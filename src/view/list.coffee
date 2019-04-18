{ Varying, DomView, mutators, List, Set } = require('janus')
{ identity } = require('janus').util

$ = require('janus-dollar')

# used to fool the render mutator into thinking there is a container element.
empty = $([])
class Wrapper
  constructor: (@contents) ->
  children: -> this.contents
  empty: ->
  append: (appended) -> this.contents = appended

# used so we don't wrap a from.varying(new Varying()) just to rewrap it on point.
dummyFrom = (item) -> { all: { point: -> new Varying(item) } }

class ListView extends DomView
  dom: -> $('<div class="janus-list"/>')

  _initialize: ->
    this._point = this.pointer()
    this.options.renderItem ?= identity

  # the default _render doesn't do much for us. do it manually.
  _render: ->
    dom = this.dom()

    # simply map the subject list into a list of their resulting views.
    # subviews work themselves out as a result as they are based on views
    # returned by the Library.
    this._mappedBindings = this.subject.map((item) => this._bindingForItem(item))
    this._hookBindings(dom, this._mappedBindings)

    # we'll have to manually add the initial set as the map will have
    # already executed and fired its events.
    dom.append(binding.dom) for binding, idx in this._mappedBindings.list

    dom # return

  # perhaps more than the other attaches, the list attach is somewhat sensitive
  # to the on-page state lining up with the model state. if the elements don't
  # line up, some really strange things can happen!
  _attach: (dom) ->
    point = this.pointer()

    # first, and attach views for each extant node+element.
    # here it gets a little tricky because we might have to account for cases where
    # each view actually has multiple root nodes.
    contents = dom.contents()
    if contents.length is this.subject.length_
      # in this case we assume everything is a single node (should be the common case).
      bindings = contents.map((idx, node) =>
        this._bindingForItem(this.subject.list[idx], $(node), false)
      ).get()
    else # otherwise we have to figure out each child's length:
      ptr = 0
      bindings = for item in this.subject.list
        # we do so by creating a throwaway binding and seeing how long its dom is.
        # TODO: possible minor perf improvement by just checking app view library
        # for the view class and checking View.fragment.length
        testBinding = this._bindingForItem(item)
        length = testBinding.dom.length
        testBinding.view.get()?.destroy()
        this._bindingForItem(item, $(contents.slice(ptr, (ptr += length))), false)

    # now what we do is sort of ugly; we still want to directly map the list
    # elements to mutator bindings, but we don't want to do this on the first
    # pass. so... we work impurely to behave differently the first go-around.
    initial = true
    this._mappedBindings = this.subject.map((item) =>
      if initial is true then bindings.shift()
      else this._bindingForItem(item)
    )
    initial = false

    this._hookBindings(dom, this._mappedBindings)
    return

  # whether we are adding or moving, all we have to do is find the appropriate
  # spot based on the binding list and insert the elements. but there are a bunch
  # of odd corner cases:
  # 1 if a data element has no dom, usually because there was no library entry for it
  # 2 reverse-order additions (there is a test by this name with a descriptive comment)
  # so we factor out and do the work here.
  _insert = (dom, list, it, idx) ->
    # first, perform and bail early for the easiest and generally most common case.
    length = list.length
    return dom.append(it.dom) if (1 + idx) is length

    # if that doesn't work, our goal is to insert the element just before the thing it
    # should be before. but if it doesn't exist we can just use the following thing, etc.
    iter = 0
    while (++iter + idx) < length when (binding = list[iter + idx])?
      if binding.dom.length > 0
        binding.dom.eq(0).before(it.dom)
        return

    # if we never find a thing it should be before, then we just append.
    dom.append(it.dom)

  # used in both render and attach workflows.
  # TODO: likely bug, if a view doesn't render and something is added immediately before.
  _hookBindings: (dom, bindings) ->
    # when our mapped bindings change, we mutate our dom.
    this.listenTo(bindings, 'added', (binding, idx) => 
      _insert(dom, bindings.list, binding, idx)
      binding.view.get()?.wireEvents() if this._wired is true
    )
    this.listenTo(bindings, 'moved', (binding, idx) => _insert(dom, bindings.list, binding, idx))
    this.listenTo(bindings, 'removed', (binding) ->
      binding.view.get()?.destroy()
      binding.stop()
      binding.dom.remove()
    )
    return

  # take a container and populate it with a view given the standard
  # pointed binding. remember the dom element so we can actually add it.
  _bindingForItem: (item, node = empty, immediate = true) ->
    wrapper = new Wrapper(node)
    mutator = mutators.render(dummyFrom(item))
    binding = this.options.renderItem(mutator)(wrapper, this._point, immediate)
    binding.dom = wrapper.contents
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


module.exports = {
  ListView
  SetView
  registerWith: (library) ->
    library.register(List, ListView)
    library.register(Set, SetView)
}

