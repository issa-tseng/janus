{ Varying, DomView, mutators, from, List, Set } = require('janus')
{ identity } = require('janus').util

$ = require('../util/dollar')

class ListView extends DomView
  dom: -> $('<ul class="janus-list"/>')
  itemDom: -> $('<li/>')

  _initialize: ->
    this._point = this.pointer()
    this.options.renderItem ?= identity

  # the default _render doesn't do much for us. do it manually.
  _render: ->
    dom = this.dom()

    # simply map the subject list into a list of their resulting views.
    # subviews work themselves out as a result as they are based on views
    # returned by the Library.
    this._mappedBindings = this.subject.map((item) => this._bindingForItem(item, this.itemDom()))
    this._hookBindings(dom, this._mappedBindings) # actually add/remove them from dom.

    # we'll have to manually add the initial set as the map will have
    # already executed and fired its events.
    insertNode(dom, binding.dom, idx) for binding, idx in this._mappedBindings.list

    dom # return

  # perhaps more than the other attaches, the list attach is somewhat sensitive
  # to the on-page state lining up with the model state. if the elements don't
  # line up, some really strange things can happen!
  # it is theoretically possible to do some heuristic checks (eg do the lengths
  # match up?) but apart from complaining it's not clear what we can do to fix
  # it; part of attach() is completely faith-based.
  attach: (dom) ->
    this._artifact = dom
    point = this.pointer()

    # first, and attach views for each extant node+element.
    bindings = dom.children().map((idx, node) =>
      this._bindingForItem(this.subject.list[idx], $(node), false)
    ).get()

    # now what we do is sort of ugly; we still want to directly map the list
    # elements to mutator bindings, but we don't want to do this on the first
    # pass. so... we work rather impurely the first go-around.
    initial = true
    this._mappedBindings = this.subject.map((item) =>
      if initial is true
        bindings.shift()
      else
        this._bindingForItem(item, this.itemDom())
    )
    initial = false

    this._hookBindings(dom, this._mappedBindings)
    return

  # used in both render and attach workflows.
  _hookBindings: (dom, bindings) ->
    # when our mapped bindings change, we mutate our dom.
    this.listenTo(bindings, 'added', (binding, idx) =>
      insertNode(dom, binding.dom, idx)
      binding.view.get()?.wireEvents() if this._wired is true
    )
    this.listenTo(bindings, 'removed', (binding) ->
      binding.view.get()?.destroy()
      binding.stop()
      binding.dom.remove()
    )

  # take a container and populate it with a view given the standard
  # pointed binding. remember the dom element so we can actually add it.
  _bindingForItem: (item, node, immediate = true) ->
    mutator = mutators.render(from.varying(Varying.of(item)))
    binding = this.options.renderItem(mutator)(node, this._point, immediate)
    binding.dom = node
    binding

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

class SetView extends ListView
  constructor: (set, options) -> super(set?._list, options)


insertNode = (dom, itemDom, idx) ->
  children = dom.children()
  if idx is 0
    dom.prepend(itemDom)
  else if idx is children.length
    dom.append(itemDom)
  else
    children.eq(idx).before(itemDom)

module.exports = {
  ListView
  SetView
  registerWith: (library) ->
    library.register(List, ListView)
    library.register(Set, SetView)
}

