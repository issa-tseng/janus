util = require('../../util/util')

DomView = require('../dom-view').DomView
reference = require('../../model/reference')
Varying = require('../../core/varying').Varying

class ListView extends DomView
  _initialize: ->
    this.options.childOpts ?= {}

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
        if idx is 0
          this._dom.prepend(elem)
        else
          afterDom = this._dom.children(":nth-child(#{idx})")
          afterDom.after(elem)
      else
        afterDom = this._dom.children(':last-child')
        afterDom.after(elem)

      afterDom = elem

    for item in items
      do =>
        view = viewDom = null

        # first check if we got a reference, since we should resolve those.
        item.value.resolve(this.options.app) if item instanceof reference.RequestReference and item.value instanceof reference.RequestResolver

        # now see if we have `Varying`s, because we should actually be rendering
        # their inner values.
        if item instanceof Varying
          varying = item
          item = varying.value

          # TODO: a little insanely and very repetitively written.
          varying.on 'changed', (newItem) =>
            # get a new one.
            newView = this._getView(newItem)
            this._views[newItem._id] = newView if newItem?

            # abort if we have nothing.
            if !newView?
              newViewDom = this._emptyDom()
              viewDom.replaceWith(newViewDom)
              viewDom = newViewDom
              return

            # render and replace.
            newViewDom = newView?.artifact() ? this._emptyDom()
            viewDom.replaceWith(newViewDom)

            # clean up and set up next iter.
            view?.destroy()
            view = newView

            # last tasks.
            view.emit('appended')
            view.wireEvents() if this._wired is true

        # grab our view.
        view = this._getView(item)
        this._views[item._id] = view if item?

        # render and drop in our view.
        viewDom = view?.artifact() ? this._emptyDom()
        insert(viewDom)

        # last tasks.
        if view?
          view.emit('appended')
          view.wireEvents() if this._wired is true

    null

  _getView: (item) ->
    if !item?
      null
    else if item instanceof DomView
      item
    else if this.options.itemView?
      new (this.options.itemView)(item, util.extendNew(this.options.childOpts, { app: this.options.app }))
    else
      this._app().getView(item, context: this.options.itemContext, constructorOpts: this.options.childOpts)

  _remove: (items) ->
    items = [ items ] unless util.isArray(items)

    for item in items
      this._views[item._id]?.destroy()
      delete this._views[item._id]

    null

  _wireEvents: -> view.wireEvents() for _, view of this._views


util.extend(module.exports,
  ListView: ListView
)

