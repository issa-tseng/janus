# The **DomView** is a `View` that makes some assumptions about its own use:
#
# * It will rely on the Janus `Templater` for rendering.
# * It returns a DOM node.
#

{ Varying } = require('../core/varying')
{ match } = require('../core/case')
{ dynamic, attr, definition, varying, app } = require('../core/from').default
View = require('./view').View
List = require('../collection/list').List
{ extendNew, extend, isFunction, isString } = require('../util/util')

class DomView extends View
  # Here we supply the internal DOM fragment we'll use to actually render.
  # Calling this method should always result in a fresh DOM fragment wrapped
  # with a jQuery-compatible API (maybe someday we'll go native).
  @_dom: -> throw new Error('no dom fragment provided!')

  # When deriving from DomView, declare a template class var so that we have
  # something to render with.
  @_template: -> throw new Error('no template provided!')

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
    dom = this.constructor._dom()

    # shuffle dance to wrap the actual contents so that .find() behaves as expected.
    dom.prepend('<div/>')
    wrapper = dom.filter(':first')
    wrapper.remove()
    wrapper.append(dom)

    # apply the bindings and save the resulting Varieds so we can stop them later.
    found = this.constructor._template(wrapper)
    this._bindings = found((x) => this.constructor._point(x, this)) #k
    dom

  # Point is provided here as a top-level class method so that it's "compiled"
  # as few times as possible. It deals with all the default cases.
  @_point: match(
    dynamic (x, view) ->
      if isFunction(x)
        Varying.ly(x(view.subject))
      else if isString(x)
        view.subject.resolve(x, view._app())
      else
        Varying.ly(x) # i guess? TODO
    attr (x, view) -> view.subject.resolve(x, view._app())
    definition (x, view) -> new Varying(view.subject.attribute(x))
    varying (x, view) -> if isFunction(x) then Varying.ly(x(view.subject)) else Varying.ly(x)
    app (x, view) -> new Varying(view._app())
  )

  # When we want to attach, we really just want to create a Templater against the
  # dom we've been given and tell it not to apply on init. We then want to feed
  # it the data we have, much like when we fully render.
  _attach: (dom) ->
    # TODO.
    null

  # Internal helper to get an App, since there's a lot of juggling we want to do
  # to get various follow-on effects to work correctly. Memoized for perf.
  _app: -> this._app$ ?= do =>
    return null unless this.options.app?

    library = this.options.app.get('views').newEventBindings()
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
    view?.wireEvents() for view in this._subviews.list
    null

  destroy: ->
    if this._artifact?
      this.artifact().trigger?('destroying')
      this.artifact().remove()
      binding.stop() for binding in this._bindings

    super()


extend(module.exports,
  DomView: DomView
)

