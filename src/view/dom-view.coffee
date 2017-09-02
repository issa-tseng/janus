# The **DomView** is a `View` that makes some assumptions about its own use:
#
# * It will rely on the Janus `Templater` for rendering.
# * It returns a DOM node.
#

View = require('./view').View
List = require('../collection/list').List


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

    this.on('appended', =>
      if this.artifact().closest('body').length > 0
        this.emit('appendedToDocument')
        subview.emit('appended') for subview in this._subviews.list
      null
    )

    this.options.app?.on('vended', (type, subview) =>
      return unless type is 'views'

      subview.wireEvents() if this._wired is true
      this._subviews.add(subview)
    )

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
    wrapper =
      if dom.parent? and (parent = dom.parent()).length > 0
        parent
      else
        dom.prepend('<div/>')
        generated = dom.children(':first-child')
        generated.remove()
        generated.append(dom)
        generated

    # apply the bindings and save the resulting Varieds so we can stop them later.
    found = this.constructor._template(wrapper)
    this._bindings = found((x) => this.constructor._point(x, this)) #k
    dom

  # When we want to attach, we really just want to create a Templater against the
  # dom we've been given and tell it not to apply on init. We then want to feed
  # it the data we have, much like when we fully render.
  _attach: (dom) ->
    # TODO.
    null

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

  _destroy: ->
    if this._artifact?
      this.artifact().trigger?('destroying')
      this.artifact().remove()
      binding.stop() for binding in this._bindings
      subview.destroy for subview in this._subviews.list
      # destroy viewmodel


module.exports = { DomView }

