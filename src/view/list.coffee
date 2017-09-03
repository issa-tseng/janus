{ Varying, DomView, mutators, from, List } = require('janus')

$ = require('../util/dollar')

class ListView extends DomView
  @_dom: -> $('<ul class="janus-list"/>')
  @_itemDom: -> $('<li/>')
  @_template: ->

  _initialize: -> this.options.renderItem ?= (x) -> x

  # the default _render doesn't do much for us. do it manually.
  _render: ->
    dom = this.constructor._dom()

    # simply map the subject list into a list of their resulting views.
    # subviews work themselves out as a result as they are based on views
    # returned by the Library.
    this._mappedBindings = this.subject.map((item) =>
      # make a container and populate it with a view given the standard
      # pointed binding. destroy the binding if the list item is removed.
      itemDom = this.constructor._itemDom()
      binding = this.options.renderItem(mutators.render(from(item)))(itemDom, (x) => this.constructor.point(x, this))

      # HACK?: decorate the binding with the dom obj.
      binding.dom = itemDom
      binding
    )

    # assign _bindings ref so view lifecycle management works out of box.
    this._bindings = this._mappedBindings.list

    # when our mapped bindings change, we mutate our dom.
    this.listenTo(this._mappedBindings, 'added', (binding, idx) => this._add(dom, binding.dom, idx))
    this.listenTo(this._mappedBindings, 'removed', (binding) => this._remove(binding))

    # we'll have to manually add the initial set as the map will have
    # already executed and fired its events.
    this._add(dom, binding.dom, idx) for binding, idx in this._mappedBindings.list

    dom # return

  _add: (dom, itemDom, idx) ->
    children = dom.children()
    if idx is 0
      dom.prepend(itemDom)
    else if idx is children.length
      dom.append(itemDom)
    else
      children.eq(idx).before(itemDom)

  _remove: (binding) ->
    binding.stop()
    binding.dom.data('subview')?.destroy()
    binding.dom.remove()

module.exports = { ListView, registerWith: (library) -> library.register(List, ListView) }

