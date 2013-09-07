util = require('../../util/util')

ViewContainer = require('./view-container').ViewContainer
reference = require('../../model/reference')
Varying = require('../../core/varying').Varying

class ListView extends ViewContainer
  _render: ->
    dom = this._dom = super()

    this._add(this.subject.list)

    this.listenTo(this.subject, 'added', (item, idx) => this._add(item, idx))
    this.listenTo(this.subject, 'removed', (item) => this._remove(item))

    dom

  _target: -> this._dom

  _add: (items, idx) ->
    items = [ items ] unless util.isArray(items)

    # TODO: messy
    afterDom = null
    target = this._target()
    insert = (elem) =>
      if target.children().length is 0
        target.append(elem)
      else if afterDom?
        afterDom.after(elem)
      else if util.isNumber(idx)
        if idx is 0
          target.prepend(elem)
        else
          afterDom = target.children(":nth-child(#{idx})")
          afterDom.after(elem)
      else
        afterDom = target.children(':last-child')
        afterDom.after(elem)

      afterDom = elem

    for item in items
      do (item) =>
        view = viewDom = null

        # first check if we got a reference, since we should resolve those.
        item.value.resolve(this.options.app) if item instanceof reference.RequestReference and item.value instanceof reference.RequestResolver

        # grab our view.
        view = this._getView(item)

        # render and drop in our view.
        viewDom = view?.artifact() ? this._emptyDom()
        insert(viewDom)

        # last tasks.
        if view?
          view.emit('appended')
          view.wireEvents() if this._wired is true

    null

  _remove: (items) ->
    items = [ items ] unless util.isArray(items)
    this._removeView(item) for item in items
    null


util.extend(module.exports,
  ListView: ListView
)

