# The base class used by Janus that provides events, behavior composition, and
# other core functionality.

EventEmitter = require('eventemitter2').EventEmitter2
util = require('../util/util')

# Extend EventEmitter into pretty much everything we do.
class Base extends EventEmitter

  # We have some things to keep track of; do so here.
  constructor: ->
    # Set some defaults on EventEmitter2.
    super(
      delimiter: ':'
      maxListeners: 0
    )

    # Keep track of who we're listening to so we can stop doing so later.
    this._listeners = []

    # Assign ourselves a globally-within-Janus unique id.
    this._id = util.uniqueId()

    # **Returns** nothing.
    null

  # Listen to another object for only the lifecycle of this object.
  #
  # **Returns** self.
  listenTo: (target, event, handler) ->
    this._listeners.push(arguments)
    target.on(event, handler)

  # `destroy()` removes all listeners this object has on others via
  # `listenTo()`, and removes all listeners other objects have on this one.
  #
  # **Returns** self.
  destroy: ->
    this.emit('destroying')
    target?.off(event, handler) for { 0: target, 1: event, 2: handler } in this._listeners
    this.removeAllListeners()

# Export.
util.extend(module.exports,
  Base: Base
)

