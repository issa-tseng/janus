{ Varying } = require('../core/varying')
{ identity, isFunction, extendNew, deepSet } = require('../util/util')

{ match, otherwise } = require('../core/case')
{ recurse, delegate, defer, varying, value, nothing } = require('../util/types').traversal


# core mechanism:

# TODO: the mechanism of passing state here is far from my favourite. someone
# please come up with something smarter/faster/cleaner.
matcher = match(
  recurse (into, context, local) -> local.root(into, local, context ? local.context)

  delegate (to, context, local) ->
    matcher(to(local.key, local.value, local.obj, local.attribute, context ? local.context),
      extendNew(local, { context }))
  defer (to, context, local) ->
    matcher(to(local.key, local.value, local.obj, local.attribute, context ? local.context),
      extendNew(local, { context, map: to }))

  varying (v, _, local) ->
    # we can indiscriminately flatMap because the only valid final values here
    # are case instances anyway, so we can't squash anything we oughtn't.
    mapped = v.flatMap((x) -> matcher(x, local))
    if local.immediate is true then mapped.get() else mapped

  value (x) -> x
  nothing -> undefined
)

# the general param should supply: root, obj, map, context, [reduce, recurse].
processNode = (general) -> (key, value) ->
  obj = general.obj
  attribute = obj.attribute(key) if obj.isModel is true
  local = extendNew(general, { key, value, attribute })
  matcher(general.map(key, value, obj, attribute, general.context), local)

# match the result of userland recurse.
prematcher = match(
  recurse (into, context, general, process) -> process(extendNew(general, { obj: into, context }))
  varying (v, context, general, process) ->
    mapped = v.flatMap((x) -> prematcher(x, general, process))
    if general.immediate is true then mapped.get() else mapped
  otherwise (x, general) -> matcher(x, general)
)

# called top-level before actually traversing a data structure.
preprocess = (general, process) ->
  prematcher((general.recurse ? recurse)(general.obj, general.context), general, process)

# wraps reduction in a managed varying for resource management.
# TODO: the double-call is not my favourite. same for the resource func.
reducer = (general, resource) -> ->
  if general.reduce? then Varying.managed(resource(general), general.reduce) else resource(general)()

Traversal =
  asNatural: (obj, fs, context = {}) ->
    general = extendNew(fs, { obj, context, root: Traversal.asNatural })
    preprocess(general, (general) -> general.obj.flatMapPairs(processNode(general)))

  asList: (obj, fs, context = {}) ->
    general = extendNew(fs, { obj, context, root: Traversal.asList })
    preprocess(general, reducer(general, (general) -> -> general.obj.enumeration().flatMapPairs(processNode(general))))

  # these two inner blocks are rather repetitive but i'm reluctant to pull them into a
  # function for perf reasons.
  #
  # n.b. val instead of value because coffeescript scoping is a mess.
  getNatural: (obj, fs, context = {}) ->
    result = if obj.isCollection is true then [] else {}
    set = if obj.isCollection is true then ((k, v) -> result[k] = v) else ((k, v) -> deepSet(result, k)(v))
    for key in obj.enumerate()
      val = obj.get(key)
      attribute = obj.attribute(key) if obj.isModel is true
      local = extendNew(fs, { obj, key, val, attribute, context, immediate: true, root: Traversal.getNatural })
      set(key, matcher(local.map(key, val, obj, attribute, context), local))
    result

  getArray: (obj, fs, context = {}) ->
    (fs.reduce ? identity)(
      for key in obj.enumerate() 
        val = obj.get(key)
        attribute = obj.attribute(key) if obj.isModel is true
        local = extendNew(fs, { obj, key, val, attribute, context, immediate: true, root: Traversal.getArray })
        matcher(local.map(key, val, obj, attribute, context), local)
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
      if (obj?.isEnumerable is true and other?.isEnumerable is true) and (obj.isCollection is other.isCollection)
        varying(Varying.mapAll(obj.watchLength(), other.watchLength(), (la, lb) ->
          if la isnt lb then value(true) else recurse(obj, { other })
        ))
      else
        value(new Varying(obj isnt other))
    map: (k, va, obj, attribute, { other }) ->
      varying(other.watch(k).map((vb) ->
        if va? and vb?
          if (va?.isEnumerable is true and vb?.isEnumerable is true) and (va.isCollection is vb.isCollection)
            recurse(va, { other: vb })
          else
            value(va isnt vb)
        else
          value(va? or vb?)
      ))
    reduce: (list) -> list.any(identity)


module.exports = { Traversal }

