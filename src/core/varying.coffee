# The **Varying** object is a possibly poorly-name object that wraps any single
# value in a wrapper that can event wher said value changes. Often it is used by
# Model objects to wrap an attribute for binding against a View, and in fact
# Models provide a method to do so.
#
# The expectation is that upon spawning a `Varying`, one will use the value's
# `listenTo` and `setValue` methods in conjuction to trigger updates. This may
# seem like a strange amount of stuff for a consumer to manage, but the API
# becomes a bit of a mess otherwise. And, Model objects do this legwork
# automatically.

Base = require('../core/base').Base
util = require('../util/util')

# Use Base so that we inherit its EventEmitter defaults
class Varying extends Base
  # Creates a new Varying. The following options may be supplied:
  #
  # - `value`: The initial value of the Varying.
  # - `transform`: A function that transforms the value before passing it on if
  #   desired.
  #
  constructor: ({ value } = {}) ->
    super()
    this.setValue(value)

  # Sets the value of this Varying and triggers the relevant events.
  #
  # **Returns** the new value.
  setValue: (value, force) ->
    # If our value is a Varying itself, we will attach ourselves to its result;
    # unless of course we're for some reason being assigned ourself, in which
    # case set null and bail.
    if value is this
      value = null
    else if value instanceof Varying
      this._childVarying?.destroy() # bad?
      this._childVarying = value
      value = this._childVarying.value

      # We turn force on, since we're already listening to a `Varying`, which
      # should be weeding out spurious fires already unless it has a reason not
      # to.
      this.listenTo(this._childVarying, 'changed', (newValue) => this._doSetValue(newValue, true))

    # Update and event if the value has indeed changed.
    this._doSetValue(value, force)

  # Return a new Varying that applies the given map on top of the existing
  # result.
  map: (f) ->
    result = new Varying( value: f(this.value) )
    result.listenTo(this, 'changed', (value) => result.setValue(f(value)))

    result

  # Print value to console as it changes for quick debugging.
  trace: (name = this._id) ->
    this.on('changed', (value) -> console.log("Varying #{name} changed:"); console.log(value))
    this

  # Breakpoint whenever this value changes.
  debug: ->
    this.on('changed', (value) -> debugger)
    this

  # process of actually storing and emitting on the value
  _doSetValue: (value, force = false) ->
    oldValue = this.value
    if force is true or value isnt oldValue
      this.value = value
      this.emit('changed', value, oldValue)

    value

  # convenience constructor since sometimes varyings are instantiate-and-forget.
  @combine: (varyings, transform) -> new MultiVarying(varyings, transform)

  # convenience constructor to ensure a Varying. wraps nonVaryings, and returns
  # Varyings given to it.
  @ly: (val) ->
    if val instanceof Varying
      val
    else
      new Varying( value: val )

# A MultiVarying takes multiple Varying objects and puts their values together.
# It doesn't itself listen to anything but Proxies directly.
class MultiVarying extends Varying

  # Unlike the base `Varying`, this one simply takes the array of Proxies and a
  # `flatMap` function for combining the results of those proxies.
  constructor: (@varyings = [], @flatMap) ->
    super()

    # Init our values array. It'll get actual values when we call `update` in
    # just a bit here.
    this.values = []

    # Listen to all our proxies for updates.
    for varying, i in this.varyings
      do (varying, i) =>
        this.values[i] = varying.value
        varying.on 'changed', (value) =>
          this.values[i] = value
          this.update()

    # We'll update immediately to set our initial state.
    this.update()

  # Call our flatMap func for combining, then just rely on `setValue` for the
  # rest of the behavior.
  #
  # **Returns** the new value.
  update: ->
    value = this.values
    value = this.flatMap(value...) if this.flatMap?
    this.setValue(value)

# Export.
util.extend(module.exports,
  Varying: Varying
  MultiVarying: MultiVarying
)

