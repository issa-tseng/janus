# The base class used by Janus that provides events, behavior composition, and
# other core functionality.

EventEmitter = require('eventemitter2').EventEmitter2
util = require('../util/util')


# Extend EventEmitter into pretty much everything we do.
class Base extends EventEmitter
  isBase: true

  # We have some things to keep track of; do so here.
  constructor: ->
    # Set some defaults on EventEmitter2.
    super(
      delimiter: ':'
      maxListeners: 0
    )

    # set max listeners for real
    this.setMaxListeners(0)

    # Keep track of who we're listening to so we can stop doing so later.
    this._outwardListeners = []
    this._outwardReactions = []

    # Assign ourselves a globally-within-Janus unique id.
    this._id = util.uniqueId()

    # Assume we have one dependency on this resource by default.
    this._refCount = 1

    # **Returns** nothing.
    null

  # Listen to another object for only the lifecycle of this object.
  #
  # **Returns** self.
  listenTo: (target, event, handler) ->
    this._outwardListeners.push(arguments)
    target?.on?(event, handler)
    this

  # Unlisten entirely to another object immediately.
  #
  # **Returns** self.
  unlistenTo: (tgt) ->
    target?.off?(event, handler) for { 0: target, 1: event, 2: handler } in this._outwardListeners when target is tgt
    this

  # Perform and track a reaction such that it is halted if this object is
  # destroyed.
  #
  # **Returns** the Observation of the reaction.
  reactTo: (varying, f_) ->
    observation = varying.react(f_)
    this._outwardReactions.push(observation)
    observation

  # Perform and track a deferred reaction such that it is halted if this
  # object is destroyed.
  #
  # **Returns** the Observation of the reaction.
  reactLaterTo: (varying, f_) ->
    observation = varying.reactLater(f_)
    this._outwardReactions.push(observation)
    observation

  # `destroy()` removes all listeners this object has on others via
  # `listenTo()`, and removes all listeners other objects have on this one.
  #
  # **Returns** self.
  destroy: ->
    if (this._refCount -= 1) is 0
      this.emit('destroying')
      target?.off?(event, handler) for { 0: target, 1: event, 2: handler } in this._outwardListeners
      o.stop() for o in this._outwardReactions
      this.removeAllListeners()
      this._destroy?()

  # Quick shortcut for expressing that this object's existence depends purely on
  # another, so it should self-destruct if the other does.
  # Normally, the garbage collector would handle this sort of thing, but with
  # listeners flying around it can be a little hard to reason out.
  #
  # **Returns** self.
  destroyWith: (other) -> this.listenTo(other, 'destroying', => this.destroy())

  # Increase the number of dependencies on this resource, which delays destruction.
  #
  # **Returns** self.
  tap: ->
    this._refCount += 1
    this

  # Creates a function which when called will always vend a resource as expressed
  # by f; but as long as the previously vended resource is still live, will vend
  # that one.
  @managed: (f) ->
    resource = null
    ->
      if resource?
        resource.tap()
      else
        resource = f.call(this)
        resource.on('destroying', -> resource = null)
        resource


module.exports = { Base }

