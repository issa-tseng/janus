# The **DomView** is a `View` that makes some assumptions about its own use:
#
# * It will rely on the Janus `Templater` for rendering.
# * It returns a DOM node.
#

util = require('../util/util')
View = require('./view').View
List = require('../collection/list').List

class DomView extends View
  # When deriving from DomView, set the templater class to determine which
  # templater to use.
  # TODO: make class var
  templateClass: null

  constructor: (@subject, @options = {}) ->
    super(@subject, @options)

    this._subviews = new List()

    this.on 'appended', =>
      if this.artifact().closest('body').length > 0
        this.emit('appendedToDocument')
        subview.emit('appended') for subview in this._subviews.list
      null

    this.destroyWith(this.subject)

  # Since we're opinionated enough here to explicitly be dealing with DOM, we
  # can also expose a `markup()` for grabbing the actual HTML.
  markup: -> (node.outerHTML for node in this.artifact().get()).join('')

  # By default, the render action for a `DomView` is simply to render out the
  # DOM via our templater and attach the binder against what we know is our
  # primary data.
  _render: ->
    this._templater = new this.templateClass(
      util.extendNew({ app: this._app() }, this._templaterOptions()))

    dom = this._templater.dom()
    this._setTemplaterData()
    dom

  # Allow for templater options to be passed in easily.
  _templaterOptions: -> {}

  # When we want to bind, we really just want to create a Templater against the
  # dom we've been given and tell it not to apply on init. We then want to feed
  # it the data we have, much like when we fully render.
  _bind: (dom) ->
    this._templater = new this.templateClass(
      app: this._app()
      dom: dom
    )

    this._setTemplaterData(false)
    null

  # Define how we set our data onto our templater, so that aux data can be
  # provided if needed.
  _setTemplaterData: (shouldRender) -> this._templater.data(this.subject, this._auxData(), shouldRender)

  # Or, if you really just want to provide some aux data, that's pretty easy
  # to allow too.
  _auxData: -> this.options.aux ? {}

  _app: -> this._app$ ?= do =>
    library = this.options.app.libraries.views.newEventBindings()
    library.destroyWith(this)

    this.listenTo library, 'got', (view) =>
      view.wireEvents() if this._wired is true
      this._subviews.add(view)

    this.options.app.withViewLibrary(library)

  # We also know enough at this implementation level to provide a default
  # implementation for event wiring: the actual wiring should still be done
  # independently of templating, but we need to cascade the wire process through
  # to children. Templater provides this.
  #
  # TODO: unclean gc
  wireEvents: ->
    return if this._wired is true
    this._wired = true

    # render our artifact before doing any wiring.
    dom = this.artifact()

    # drop a ref to ourself in the data.
    dom.data('view', this)

    this._wireEvents()
    view?.wireEvents() for view in this._subviews.list if this._subviews?
    null

  destroy: ->
    if this._artifact?
      this.artifact().trigger?('destroying')
      this.artifact().remove()

    super()


util.extend(module.exports,
  DomView: DomView
)

