# **Views** are very general abstractions that are expected to generate one
# artifact (commonly but not always a DOM object), bind events against it, and
# be able to rebind to them when asked to.
#
# It's recommended but optional that one use the templating engine Janus
# supplies with its Views.

Base = require('../core/base').Base
{ Varying } = require('../core/varying')
{ dynamic, watch, resolve, attribute, varying, app, self } = require('../core/types').from
{ match } = require('../core/case')
{ isFunction, isString } = require('../util/util')


# Base gives us event listening things
class View extends Base

  # The `View` takes first and foremost a `subject`, which is the object it aims
  # to create a view for. It also takes an `options` hash, which has no
  # predefined behavior.
  constructor: (subject, @options = {}) ->
    super()

    # If we have a reference to a ViewModel intermediary, instantiate it and
    # inject our actual subject. Otherwise, accept as-is.
    # TODO: destroy viewModel on View destruction.
    this.subject =
      if this.constructor.viewModelClass?
        new this.constructor.viewModelClass({ view: this, options: this.options, subject }, { app: this.options.app })
      else
        subject

    this._initialize?()

  # Returns the artifact this View is managing. If it has not yet created one,
  # the View will delegate to `_render()` to create one. That method has no
  # default implementation.
  #
  # **Returns** artifact object.
  artifact: -> this._artifact ?= this._render()
  _render: -> # implement me!

  # Standard point implementation that all subclasses can typically use unaltered.
  pointer: -> this.pointer$ ?= match(
    dynamic (x) =>
      if isFunction(x)
        Varying.of(x(this.subject))
      else if isString(x) and this.subject.watch?
        this.subject.watch(x)
      else
        Varying.of(x)
    watch (x) => this.subject.watch(x)
    attribute (x) => new Varying(this.subject.attribute(x))
    varying (x) => if isFunction(x) then Varying.of(x(this.subject)) else Varying.of(x)
    app (x) =>
      if x? then this.options.app.watch(x)
      else new Varying(this.options.app)
    self (x) => if isFunction(x) then Varying.of(x(this)) else Varying.of(this)
  )

  # Wires events against the artifact in question. This method is separate so
  # that:
  #
  # 1. It doesn't need to be needless run on the server.
  # 2. It can be deferred even on the client until it might be necessary.
  #
  # Delegates to `_wireEvents()` to do the actual wiring. Only allows it to be
  # run once. And of course, there is no default implementation.
  #
  # **Returns** nothing.
  wireEvents: ->
    this._wireEvents() unless this._wired
    this._wired = true
    null
  _wireEvents: -> # implement me!


module.exports = { View }

