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


# util:
get = (obj, k) ->
  if obj.isCollection is true
    obj.at(k)
  else if obj.isStruct is true
    obj.get(k)
watch = (obj, k) ->
  if obj.isCollection is true
    obj.watchAt(k)
  else if obj.isStruct is true
    obj.watch(k)


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
  attribute = obj.attribute(key) if obj.isModel is true and obj.isCollection isnt true # this line sucks.
  local = extendNew(general, { key, value, attribute })
  matcher(general.map(key, value, obj, attribute, general.context), local)

Traversal =
  asNatural: (obj, map, context = {}) ->
    general = { obj, map, context, root: Traversal.asNatural }
    if obj.isCollection is true
      obj.enumeration().flatMapPairs(processNode(general))
    else
      obj.flatMap?(processNode(general))

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
      val = get(obj, key)
      attribute = obj.attribute(key) if obj.isModel is true and obj.isCollection isnt true # this line still sucks.
      local = { obj, map, key, val, attribute, context, immediate: true, root: Traversal.getNatural }
      set(key, matcher(map(key, val, obj, attribute, context), local))
    result

  getArray: (obj, map, context = {}, reduce = identity) ->
    reduce(
      for key in obj.enumerate() 
        val = get(obj, key)
        attribute = obj.attribute(key) if obj.isModel is true and obj.isCollection isnt true # yup.
        local = { obj, map, reduce, key, val, attribute, context, immediate: true, root: Traversal.getArray }
        matcher(map(key, val, obj, attribute, context), local)
    )


# default impl:
# swap out our matching cases for our value cases for the impl section:
{ recurse, delegate, defer, varying, value, nothing } = valueCases

Traversal.default =
  serialize: (k, v, o, attribute, context) ->
    if attribute?
      value(attribute.serialize())
    else if v?
      if v.isEnumerable is true
        recurse(v)
      else
        value(v)
    else
      nothing

  modified:
    map: (k, va, obj, attribute, context) ->
      if !obj._parent?
        value(false)
      else
        varying(watch(obj._parent, k).map((vb) ->
          if va?.isEnumerable is true
            if vb is va._parent
              vla = if va.isCollection is true then va.watchLength() else va.enumeration().watchLength()
              vlb = if vb.isCollection is true then vb.watchLength() else vb.enumeration().watchLength()
              varying(Varying.mapAll(vla, vlb, (la, lb) -> if la isnt lb then value(true) else recurse(va)))
            else
              value(true)
          else
            value(va isnt vb)
        ))
    reduce: (list) -> list.any(identity)

  diff:
    map: (obj, k, va, attribute, { other }) ->
      vb = if other? then get(other, k) else null
      if !va? and !vb?
        value(false)
      else if va? and vb?
        if va.isCollection is true and vb.isCollection is true
          varying(from(va.watchLength()).and(vb.watchLength()).all.plain().map((la, lb) ->
            if la isnt lb then value(true) else recurse(va, other: vb )
          ))
        else if va.isStruct is true and vb.isStruct is true
          varying(from(va.enumeration().watchLength()).and(vb.enumeration().watchLength()).all.plain().map((la, lb) ->
            if la isnt lb then value(true) else recurse(va, other: vb )
          ))
        else
          value(va is vb)
      else
        value(true)
    reduce: (list) -> list.any((x) -> x is true)


module.exports = { Traversal, cases: valueCases }

