# The **Monitor** object is a possibly poorly-name object that wraps any single
# value in a wrapper that can event wher said value changes. Often it is used by
# Model objects to wrap an attribute for binding against a View, and in fact
# Models provide a method to do so.
#
# The expectation is that upon spawning a `Monitor`, one will use the value's
# `listenTo` and `setValue` methods in conjuction to trigger updates. This may
# seem like a strange amount of stuff for a consumer to manage, but the API
# becomes a bit of a mess otherwise. And, Model objects do this legwork
# automatically.

Base = require('../core/base').Base
util = require('../util/util')

# Use Base so that we inherit its EventEmitter defaults
class Monitor extends Base
  # Creates a new Monitor. The following options may be supplied:
  #
  # - `value`: The initial value of the Monitor.
  # - `transform`: A function that transforms the value before passing it on if
  #   desired.
  #
  constructor: ({ value, @transform } = {}) ->
    super()
    this.setValue(value)

  # Sets the value of this Monitor and triggers the relevant events.
  #
  # **Returns** the new value.
  setValue: (value) ->
    # Perform a transformation if we're expected to.
    value = this.transform(value) if this.transform?

    # if our transform returns a Monitor itself, we will attach ourselves to its
    # result.
    if value instanceof Monitor
      this._childMonitor?.destroy()
      this._childMonitor = value
      value = this._childMonitor.value
      this.listenTo(this._childMonitor, (newValue) => this.setValue(newValue))

    # Update and event if the value has indeed changed.
    if value isnt oldValue
      this.value = value
      this.emit('changed', value, oldValue)

    oldValue = value

    value

# A ComboMonitor takes multiple Monitor objects and puts their values together.
# It doesn't itself listen to anything but Proxies directly.
class ComboMonitor extends Monitor

  # Unlike the base `Monitor`, this one simply takes the array of Proxies and a
  # `transform` function for combining the results of those proxies.
  constructor: (@monitors = [], transform) ->
    super( transform: transform )

    # Init our values array. It'll get actual values when we call `update` in
    # just a bit here.
    this.values = []

    # Listen to all our proxies for updates.
    for monitor, i in this.monitors
      do (monitor, i) =>
        this.values[i] = monitor.value
        monitor.on 'changed', (value) =>
          this.values[i] = value
          this.update()

    # We'll update immediately to set our initial state.
    this.update()

  # Call our transform func for combining, then just rely on `setValue` for the
  # rest of the behavior.
  #
  # **Returns** the new value.
  update: ->
    value = this.values
    value = this.transform(value...) if this.transform?
    this.setValue(value)

# Export.
util.extend(module.exports,
  Monitor: Monitor
  ComboMonitor: ComboMonitor
)

