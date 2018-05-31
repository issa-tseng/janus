# **Views** are very general abstractions that are expected to generate one
# artifact (commonly but not always a DOM object), bind events against it, and
# be able to rebind to them when asked to.
#
# It's recommended but optional that one use the templating engine Janus
# supplies with its Views.

Base = require('../core/base').Base
{ Varying } = require('../core/varying')
{ dynamic, watch, resolve, attribute, varying, app, self } = require('../core/from').default
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

  # Standard point implementation that all subclasses can typically use
  # unaltered. It is provided as a top-level class method so that it is
  # "compiled" as few times as possible.
  @point: match(
    dynamic (x, view) ->
      if isFunction(x)
        Varying.ly(x(view.subject))
      else if isString(x) and view.subject.resolve?
        view.subject.resolve(x, view.options.app)
      else
        Varying.ly(x) # i guess? TODO
    watch (x, view) -> view.subject.watch(x)
    resolve (x, view) -> view.subject.resolve(x, view.options.app)
    attribute (x, view) -> new Varying(view.subject.attribute(x))
    varying (x, view) -> if isFunction(x) then Varying.ly(x(view.subject)) else Varying.ly(x)
    app (x, view) -> if x? then view.options.app.resolve(x) else new Varying(view.options.app)
    self (x, view) -> if isFunction(x) then Varying.ly(x(view)) else Varying.ly(view)
  )

  # Since View@point() wants two parameters, the target and the view instance,
  # it gets tedious to write (x) => this.constructor.point(x, this) all the time.
  # So all this instance method really does is perform that boilerplate for you.
  pointer: -> (x) => this.constructor.point(x, this)

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

  # Method that given an artifact will attach against it for live state, as if it
  # were a render. For example, if the artifact is a DOM tree, and in the normal
  # `_render()` the View would attach a text field against the model's `name`,
  # then `_attach()` should find that text field and attach it against its current
  # model.
  #
  # No implementation is provided, but the Templater built into Janus provides a
  # option on instantiation that posits this behaviour.
  #
  # **Returns** nothing.
  attach: (artifact) ->
    this._artifact = artifact
    this._attach(artifact)
    null
  _attach: ->


module.exports = { View }

