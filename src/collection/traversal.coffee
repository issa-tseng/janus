{ Varying } = require('../core/varying')
{ identity, isFunction, deepSet, fix } = require('../util/util')

{ match, otherwise } = require('../core/case')
{ recurse, delegate, defer, varying, value, nothing } = require('../core/types').traversal


# core mechanism:

# TODO: the method of passing state here is far from my favourite. someone
# please come up with something smarter/faster/cleaner.
# TODO: if someone can come up with a clever way to implement diff etc without
# relying on context, all of this gets way simpler.

# called to process the action given by the caller in their map() function.
# calls on the local context to perform various concrete actions. used by
# both the live traversals up here and the static ones at the bottom.
matchAction = (local) -> fix((rematch) -> match(
  recurse (into, context) -> local.root(into, local, context ? local.context)

  delegate (to, context) ->
    newlocal = Object.assign({}, local, { context })
    matchAction(newlocal)(to(local.key, local.value, local.obj, local.attribute, context ? local.context))
  defer (to, context) ->
    newlocal = Object.assign({}, local, { context, map: to })
    matchAction(newlocal)(to(local.key, local.value, local.obj, local.attribute, context ? local.context))

  varying (v) ->
    # we can indiscriminately flatMap because the only valid final values here
    # are case instances anyway, so we can't squash anything we oughtn't.
    mapped = v.flatMap((x) -> rematch(x))
    if local.immediate is true then mapped.get() else mapped

  value (x) -> x
  nothing -> undefined
))

# the general param should supply: root, obj, map, context, [reduce, recurse].
processElem = (general) -> (key, value) ->
  obj = general.obj
  attribute = obj.attribute(key) if obj.isModel is true
  local = Object.assign({}, general, { key, value, attribute })
  matchAction(local)(general.map(key, value, obj, attribute, general.context))

# entrypoint; called top-level before actually traversing a data structure, so
# the first recurse() call enters the structure itself.
processRoot = (general, process) ->
  matchRootAction = match(
    recurse (into, context) -> process(Object.assign({}, general, { obj: into, context }))
    varying (v, context) ->
      mapped = v.flatMap((x) -> matchRootAction(x))
      if general.immediate is true then mapped.get() else mapped
    otherwise (x) -> matchAction(general)(x)
  )
  matchRootAction((general.recurse ? recurse)(general.obj, general.context))

# wraps reduction in a managed varying for resource management.
# TODO: the double-call is not my favourite. same for the resource func.
reducer = (general, resource) -> ->
  if general.reduce? then Varying.managed(resource(), general.reduce) else resource()()

# the actual runners that set state and call into the above. the first two return
# live traversals; the second two just do the work. both depend on matchAction above.
Traversal =
  asNatural: (obj, fs, context = {}) ->
    general = Object.assign({}, fs, { obj, context, root: Traversal.asNatural })
    fmapper = processElem(general) # init first to save calls.
    processRoot(general, -> general.obj.flatMapPairs(fmapper))

  asList: (obj, fs, context = {}) ->
    general = Object.assign({}, fs, { obj, context, root: Traversal.asList })
    fmapper = processElem(general) # ditto saving calls.
    processRoot(general, reducer(general, -> -> general.obj.enumeration().flatMapPairs(fmapper)))

  # these two inner blocks are rather repetitive but i'm reluctant to pull them into a
  # function for perf reasons.
  #
  # n.b. val instead of value because coffeescript scoping is a mess.
  getNatural: (obj, fs, context = {}) ->
    result = if obj.isMappable is true then [] else {}
    set = if obj.isMappable is true then ((k, v) -> result[k] = v) else ((k, v) -> deepSet(result, k)(v))
    for key in obj.enumerate()
      val = obj.get(key)
      attribute = obj.attribute(key) if obj.isModel is true
      local = Object.assign({}, fs, { obj, key, value: val, attribute, context, immediate: true, root: Traversal.getNatural })
      set(key, matchAction(local)(local.map(key, val, obj, attribute, context)))
    result

  getArray: (obj, fs, context = {}) ->
    (fs.reduce ? identity)(
      for key in obj.enumerate() 
        val = obj.get(key)
        attribute = obj.attribute(key) if obj.isModel is true
        local = Object.assign({}, fs, { obj, key, value: val, attribute, context, immediate: true, root: Traversal.getArray })
        matchAction(local)(local.map(key, val, obj, attribute, context))
    )


# default impl:
Traversal.default =
  serialize:
    map: (k, v, _, attribute) ->
      if attribute?
        value(attribute.serialize())
      else if v?
        # TODO: what if you /do/ want to use something from an intermediate inheritance?
        if v.constructor?.prototype.hasOwnProperty('serialize')
          value(v.serialize())
        else if v.isEnumerable is true
          recurse(v)
        else
          value(v)
      else
        nothing

  diff:
    recurse: (obj, { other }) ->
      if (obj?.isEnumerable is true and other?.isEnumerable is true) and (obj.isMappable is other.isMappable)
        varying(Varying.mapAll(obj.watchLength(), other.watchLength(), (la, lb) ->
          if la isnt lb then value(true) else recurse(obj, { other })
        ))
      else
        value(new Varying(obj isnt other))
    map: (k, va, obj, attribute, { other }) ->
      varying(other.watch(k).map((vb) ->
        if va? and vb?
          if (va?.isEnumerable is true and vb?.isEnumerable is true) and (va.isMappable is vb.isMappable)
            recurse(va, { other: vb })
          else
            value(va isnt vb)
        else
          value(va? or vb?)
      ))
    reduce: (list) -> list.any()


module.exports = { Traversal }

