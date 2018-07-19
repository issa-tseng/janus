{ Varying, DomView, mutators, from, List } = require('janus')
{ identity } = require('janus').util

$ = require('../util/dollar')

class ListView extends DomView
  dom: -> $('<ul class="janus-list"/>')
  itemDom: -> $('<li/>')

  _initialize: -> this.options.renderItem ?= identity

  # the default _render doesn't do much for us. do it manually.
  _render: ->
    dom = this.dom()
    point = this.pointer()

    # simply map the subject list into a list of their resulting views.
    # subviews work themselves out as a result as they are based on views
    # returned by the Library.
    this._mappedBindings = this.subject.map((item) =>
      # make a container and populate it with a view given the standard
      # pointed binding. remember the dom element so we can actually add it.
      itemDom = this.itemDom()
      binding = this.options.renderItem(mutators.render(from.varying(Varying.of(item))))(itemDom, point)

      binding.dom = itemDom
      binding
    )

    # when our mapped bindings change, we mutate our dom.
    this.listenTo(this._mappedBindings, 'added', (binding, idx) =>
      insertNode(dom, binding.dom, idx)
      binding.view.get()?.wireEvents() if this._wired is true
    )
    this.listenTo(this._mappedBindings, 'removed', (binding) ->
      binding.view.get()?.destroy()
      binding.stop()
      binding.dom.remove()
    )

    # we'll have to manually add the initial set as the map will have
    # already executed and fired its events.
    insertNode(dom, binding.dom, idx) for binding, idx in this._mappedBindings.list

    dom # return

  wireEvents: ->
    # first run the main loop, which will just wire our direct events.
    return if this._wired is true
    super()

    # actually wire whatever we currently have, then make sure if any flattened
    # Varyings change we also wire those new views.
    binding.view.get()?.wireEvents() for binding in this._mappedBindings.list
    this._wireObservations = this._mappedBindings.map((binding) =>
      this.reactTo(binding.view, false, (view) -> view.wireEvents()))
    this.listenTo(this._wireObservations, 'removed', (obs) -> obs.stop())
    return

  # because we completely ignore how _render is normally done, we also need to
  # do a little dance to get destroy to work.
  __destroy: ->
    if this._mappedBindings?
      this._bindings = this._mappedBindings.list.slice()
      super()
      this._mappedBindings.destroy()

    this._wireObservations?.destroy()


insertNode = (dom, itemDom, idx) ->
  children = dom.children()
  if idx is 0
    dom.prepend(itemDom)
  else if idx is children.length
    dom.append(itemDom)
  else
    children.eq(idx).before(itemDom)

module.exports = { ListView, registerWith: (library) -> library.register(List, ListView) }

