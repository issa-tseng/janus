# The base class used by Janus that provides events, but is almost entirely
# focused on resource and memory management.

EventEmitter = require('eventemitter2').EventEmitter2


class Base
  constructor: ->
    # Keep track of who we're listening to so we can stop doing so later.
    this._outwardListeners = []
    this._outwardReactions = []

    # Assume we have one dependency on this resource by default.
    this._refCount = 1

  # provide a lazy eventemitter-like interface.
  # only coerce an eventemitter into reality if someone actually listens.
  # ignore all other requests to do anything.
  on: (type, listener) ->
    this.events ?= new EventEmitter({ delimeter: ':', maxListeners: 0 })
    this.events.on(type, listener)
    this
  off: (type, listener) -> this.events?.off(type, listener); this
  emit: (e, x, y) -> # falls through as the original returns boolean.
    return false unless this.events?
    # mimic the EE2 internal arg-counting logic for perf.
    length = arguments.length
    if length is 2
      this.events.emit(e, x)
    else if length is 3
      this.events.emit(e, x, y)
    else
      EventEmitter.prototype.emit.apply(this.events, arguments)

  listeners: -> this.events?.listeners() ? []
  removeAllListeners: -> this.events?.removeAllListeners()

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
  reactTo: (varying, x, y) ->
    observation = varying.react(x, y)
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
      this.__destroy?() # for framework internals
    return

  # Quick shortcut for expressing that this object's existence depends purely on
  # another, so it should self-destruct if the other does.
  # Normally, the garbage collector would handle this sort of thing, but with
  # listeners flying around it can be a little hard to reason out.
  #
  # **Returns** self.
  destroyWith: (other) -> this.listenTo(other, 'destroying', => this.destroy()); return

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

