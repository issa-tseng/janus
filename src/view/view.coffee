# **Views** are very general abstractions that are expected to generate one
# artifact (commonly but not always a DOM object), bind events against it, and
# be able to rebind to them when asked to.
#
# It's recommended but optional that one use the templating engine Janus
# supplies with its Views.

Base = require('../core/base').Base
util = require('../util/util')

# Base gives us event listening things
class View extends Base

  # The `View` takes first and foremost a `subject`, which is the object it aims
  # to create a view for. It also takes an `options` hash, which has no
  # predefined behavior.
  constructor: (subject, @options = {}) ->
    super()

    # If we have a reference to a ViewModel intermediary, instantiate it and
    # inject our actual subject. Otherwise, accept as-is.
    this.subject =
      if this.constructor.viewModelClass?
        attrs =
          if this.options.settings?
            { settings: this.options.settings, subject }
          else
            { subject }
        new this.constructor.viewModelClass(attrs)
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

  # Method that given an artifact will bind against it for live state, as if it
  # were a render. For example, if the artifact is a DOM tree, and in the normal
  # `_render()` the View would bind a text field against the model's `name`,
  # then `_rebind()` should find that text field and bind it against its current
  # model.
  #
  # No implementation is provided, but the Templater built into Janus provides a
  # option on instantiation that posits this behaviour.
  #
  # **Returns** nothing.
  bind: (artifact) ->
    this._artifact = artifact
    this._bind(artifact)
    null
  _bind: ->

# Export.
util.extend(module.exports,
  View: View
)

