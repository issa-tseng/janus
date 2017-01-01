{ Varying } = require('../core/varying')
{ defcase, match } = require('../core/case')
{ identity, isFunction, extendNew, deepSet } = require('../util/util')


# core cases:

# some shuffling to allow two arguments in our cases. TODO: worth it? cleverer way?
withContext = (name) -> { "#{name}": { unapply: (x, additional) -> if isFunction(x) then x(this.value[0], this.value[1], additional...) else x } }

matchCases = { recurse, delegate, defer, varying, value, nothing } = defcase('org.janusjs.traversal', (withContext(x) for x in [ 'recurse', 'delegate', 'defer', 'varying', 'value', 'nothing' ])...)
valueCases = {} # external cases set that wraps two args into an array.
for k, kase of matchCases
  do (kase) -> valueCases[k] = (x, context) -> kase([ x, context ])


# core mechanism:

# TODO: the mechanism of passing state here is far from my favourite. someone
# please come up with something smarter/faster/cleaner.
matcher = match(
  recurse (into, context, local) -> local.root(into, local.map, context ? local.context, local.reduce)
  delegate (to, context, local) -> matcher(to(local.key, local.value, local.obj, local.attribute, context ? local.context), extendNew(local, { context }))
  defer (to, context, local) -> matcher(to(local.key, local.value, local.obj, local.attribute, context ? local.context), extendNew(local, { context, map: to }))
  varying (v, _, local) ->
    # we can indiscriminately flatMap because the only valid final values here
    # are case instances anyway, so we can't squash anything we oughtn't.
    result = v.flatMap((x) -> matcher(x, local))
    result = result.get() if local.immediate is true
    result
  value (x) -> x
  nothing -> undefined
)

# the general param should supply: root, obj, map, context, and [reduce if applicable].
processNode = (general) -> (key, value) ->
  obj = general.obj
  attribute = obj.attribute(key) if obj.isModel is true
  local = extendNew(general, { key, value, attribute })
  matcher(general.map(key, value, obj, attribute, general.context), local)

Traversal =
  asNatural: (obj, map, context = {}) ->
    general = { obj, map, context, root: Traversal.asNatural }
    obj.flatMapPairs(processNode(general)) if obj.isEnumerable is true

  asList: (obj, map, context = {}, reduce = identity) ->
    reduce(obj.enumeration().flatMapPairs(processNode({ obj, map, context, reduce, root: Traversal.asList })))

  # these two inner blocks are rather repetitive but i'm reluctant to pull them into a
  # function for perf reasons.
  #
  # n.b. val instead of value because coffeescript scoping is a mess.
  getNatural: (obj, map, context = {}) ->
    result = if obj.isCollection is true then [] else {}
    set = if obj.isCollection is true then ((k, v) -> result[k] = v) else ((k, v) -> deepSet(result, k)(v))
    for key in obj.enumerate()
      val = obj.get(key)
      attribute = obj.attribute(key) if obj.isModel is true
      local = { obj, map, key, val, attribute, context, immediate: true, root: Traversal.getNatural }
      set(key, matcher(map(key, val, obj, attribute, context), local))
    result

  getArray: (obj, map, context = {}, reduce = identity) ->
    reduce(
      for key in obj.enumerate() 
        val = obj.get(key)
        attribute = obj.attribute(key) if obj.isModel is true
        local = { obj, map, reduce, key, val, attribute, context, immediate: true, root: Traversal.getArray }
        matcher(map(key, val, obj, attribute, context), local)
    )


# default impl:
# swap out our matching cases for our value cases for the impl section:
{ recurse, delegate, defer, varying, value, nothing } = valueCases

Traversal.default =
  serialize: (k, v, _, attribute) ->
    if attribute?
      value(attribute.serialize())
    else if v?
      if v.isEnumerable is true
        recurse(v)
      else
        value(v)
    else
      nothing

  # TODO: do we even want this? it's such a weird and specific test in some ways.
  modified:
    map: (k, va, obj) ->
      if !obj._parent?
        value(false)
      else
        varying(obj._parent.watch(k).map((vb) ->
          if va?.isEnumerable is true
            if vb is va._parent # reject unless our parent's value here is our value's direct parent.
              varying(Varying.mapAll(va.watchLength(), vb.watchLength(), (la, lb) ->
                if la isnt lb then value(true) else recurse(va)
              ))
            else
              value(true)
          else
            value(va isnt vb)
        ))
    reduce: (list) -> list.any(identity)

  diff:
    map: (k, va, obj, attribute, { other }) ->
      varying(other.watch(k).map((vb) ->
        if !va? and !vb?
          value(false)
        else if va? and vb?
          if (va.isEnumerable is true and vb.isEnumerable is true) and (va.isCollection is vb.isCollection)
            varying(Varying.mapAll(va.watchLength(), vb.watchLength(), (la, lb) ->
              if la isnt lb then value(true) else recurse(va, other: vb )
            ))
          else
            value(va isnt vb)
        else
          value(true)
      ))
    reduce: (list) -> list.any(identity)

Traversal.cases = valueCases


module.exports = { Traversal }

