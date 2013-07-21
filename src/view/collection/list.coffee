util = require('../../util/util')

DomView = require('../dom-view').DomView

class ListView extends DomView
  _render: ->
    dom = this._dom = super()

    this._views = {}
    this._add(this.subject.list)

    this.listenTo(this.subject, 'added', (item, idx) => this._add(item, idx))
    this.listenTo(this.subject, 'removed', (item) => this._remove(item))

    dom

  _add: (items, idx) ->
    items = [ items ] unless util.isArray(items)

    # TODO: messy
    afterDom = null
    insert = (elem) =>
      if this._dom.children().length is 0
        this._dom.append(elem)
      else if afterDom?
        afterDom.after(elem)
      else if util.isNumber(idx)
        afterDom = this._dom.children(":nth-child(#{idx})")
        afterDom.after(elem)
      else
        afterDom = this._dom.children(':last-child')
        afterDom.after(elem)

      afterDom = elem

    for item in items
      view = this._getView(item)
      this._views[item._id] = view

      viewDom = view.artifact()
      wrappedViewDom = this._wrapChild(viewDom)
      insert(viewDom)
      view.emit('appended')

      view.wireEvents() if this._wired is true

    null

  _getView: (item) ->
    view =
      if item instanceof DomView
        # TODO: is this acceptable?
        item
      else if this.options.itemView?
        new (this.options.itemView)(item, app: this.options.app)
      else
        this._app().getView(item, context: this.options.itemContext)

    view.wireEvents() if this._wired is true
    view

  _remove: (items) ->
    items = [ items ] unless util.isArray(items)

    for item in items
      this._views[item._id]?.destroy()
      delete this._views[item._id]

    null

  _wrapChild: (child) -> child.wrap('<li/>').parent()

  _wireEvents: -> view.wireEvents() for _, view of this._views


util.extend(module.exports,
  ListView: ListView
)

