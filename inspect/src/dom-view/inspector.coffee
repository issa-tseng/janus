{ DomView, Varying, List, Model, attribute, bind, from, types, Library } = require('janus')
{ isPlainObject } = require('janus').util
#$ = require('../dollar')
{ noop } = require('../util')


################################################################################
# BINDING DETERMINATION
# because of how purely functional the view system is, we have to do a lot of
# working-backwards to actually figure out what bindings are trying to do what.

# util.
last = (arr) -> arr[arr.length - 1]
div = $('<div/>') # TODO: relying on global here.

# TODO: not perfect enough an imitation for some cases probably:
class DummyApp extends Model
  view: noop

voidPointer = -> ->
  result = new Varying(new DummyApp())
  result.map = -> result
  result.flatten = -> result
  result.flatMap = -> result
  result.pipe = -> result
  result

forceArtifact = (view) ->
  try
    view.artifact()
  catch # something is out of our expectation. force default _render and pray.
    view._render = DomView.prototype._render
    try view.artifact()
  return

# the domspy judges, based on the methods that are called on it, which mutator
# is being called on it. only works with out-of-the-box mutators for now.
class DomSpy
  constructor: (@selector, @operations) ->

  # straightforward operations:
  toggleClass: (param) -> this.operations.push(new Mutation(this.selector, 'classed', param))
  css: (param) -> this.operations.push(new Mutation(this.selector, 'css', param))
  html: -> this.operations.push(new Mutation(this.selector, 'html'))
  prop: (param) -> this.operations.push(new Mutation(this.selector, 'prop', param))
  text: -> this.operations.push(new Mutation(this.selector, 'text'))

  # attr is used by both attr and classGroup, so we must mux. if we are called
  # with no value at all, we know it is a pre-classGroup check, since safe() will
  # take nullish values down to ''.
  _pendingClassGroup: false
  attr: (param, value) ->
    if param is 'class' and value is undefined
      this._pendingClassGroup = true
      return ''
    else if this._pendingClassGroup is true
      this._pendingClassGroup = false
      prefix = value.slice(0, -4) # true is always given as the value
      this.operations.push(new Mutation(this.selector, 'classGroup', param: prefix))
    else
      this.operations.push(new Mutation(this.selector, 'attr', param))

  # render uses these three. it always calls children() first (and exactly once),
  # so we use that one and ignore the rest.
  # TODO: we can use our dummy app to track the render parameters.
  children: -> this.operations.push(new Mutation(this.selector, 'render'))
  empty: noop
  append: noop

  # on/off are handled separately, because they aren't bound in a way that the
  # spy can easily see.
  on: noop
  off: noop

# here we do the actual work of crafting a fake view and running the DomSpy against
# it to figure out our bindings.
deduceMutators = (view) ->
  # 0. fail out if it's not a standard template view.
  return unless view?.constructor?.template?

  # 1. create our tracking fragment, attached to our operations log.
  operations = []
  fragment = {
    find: (selector) -> { map: -> { map: -> new DomSpy(selector, operations) } }
    wrapAll: -> this
    parent: -> fragment
    get: noop
  }

  # 2a instantiate a view and do a little dance to get it to latch onto our spy
  # fragment rather than use its own. we have to sub out the viewWodelClass in
  # case it actually expects some data to exist to bind.
  vmc = view.constructor.viewModelClass
  view.constructor.viewModelClass = null
  dummy = new (view.constructor)(new Model())
  view.constructor.viewModelClass = vmc
  dummy.preboundTemplate = view.constructor.template(fragment)
  dummy.dom = -> div

  # 2b now give it a false pointer; we don't need anything out of this other than
  # for the point operation to effortlessly succeed.
  dummy.pointer = voidPointer

  # 2c now force an artifact to actually get binding to occur and make sure it did.
  forceArtifact(dummy)
  return unless dummy._bindings?

  # 3. now that we have bindings, go through each one in turn, trigger its mutator,
  # and see from the operations spy what we got out of it.
  for binding in dummy._bindings
    if typeof binding.start is 'function'
      null # sentinel null for now that gets stripped out later.
    else
      try # TODO: this try/catch approach is a hack.
        binding.f_(true)
      catch
        binding.f_(null)
      operations.pop()


################################################################################
# INSPECTOR MODELS
# not much to them, actually.

class Mutation extends Model
  constructor: (a, b, c) ->
    if isPlainObject(a) then super(a, b)
    else super({ selector: a, operation: b, param: c })

class DomViewInspector extends Model.build(
    bind('subtype', from('target')
      .map((domview) -> domview.constructor.name)
      .map((name) -> if name? and (name not in [ 'DomView', '_Class' ]) then ".#{name}" else ''))
  )

  isInspector: true

  constructor: (domview, options) ->
    # get Mutations that represent the binding operations but aren't yet tied
    # to the actual Varying bindings of this instance.
    mutations =
      if !domview? then []
      else if (extractor = this.constructor.extractors.get(domview))?
        extractor(domview)
      else if this.constructor.cache.has(domview.constructor)
        this.constructor.cache.get(domview.constructor)
      else
        result = deduceMutators(domview)
        this.constructor.cache.set(domview.constructor, result)
        result

    # now we force the artifact so that we can attach to the bindings of this instance.
    try domview.artifact()

    # we would like to match the generic mutator definitions we've just derived with
    # the actual databindings we just generated, but we need to account for some
    # failure/nonstandard-view cases while we do so:
    if domview._bindings?
      mutations =
        if mutations?
          for binding, idx in domview._bindings when (mutation = mutations[idx])?
            mutation.with({ binding: binding.parent, target: domview })
        else
          for binding, idx in domview._bindings
            mutation = new Mutation({ idx })
            mutation.set('binding', binding.parent)
            mutation

    # if we got here with nothing we have some sort of custom view we can't handle.
    mutations ?= []

    # flag mutations which share a selector with their predecessor.
    # TODO: is there a better way to do this?
    for mutation, idx in mutations when idx > 0
      if mutations[idx - 1].get_('selector') is mutation.get_('selector')
        mutation.set('repeated-selector', true)

    super({ target: domview, mutations: new List(mutations) }, options)

  @inspect: (domview) -> new DomViewInspector(domview)
  @cache: new WeakMap()
  @extractors: new Library()

  @indexFor: ({ selector, operation, param }, domview) ->
    if this.cache.has(domview.constructor)
      mutators = this.cache.get(domview.constructor)
    else
      mutators = deduceMutators(domview)
      this.cache.set(domview.constructor, mutators)

    for m, idx in mutators
      if m.get_('selector') isnt selector then continue
      if m.get_('operation') isnt operation then continue
      if param? and m.get_('param') isnt param then continue
      return idx
    return null


module.exports = {
  Mutation, DomViewInspector,
  registerWith: (library) -> library.register(DomView, DomViewInspector.inspect)
}

