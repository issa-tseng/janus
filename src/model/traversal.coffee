{ from } = require('../core/from')
{ defcase, match } = require('../core/case')
{ identity, isFunction, extendNew } = require('../util/util')


# core cases:

# some shuffling to allow two arguments in our cases. TODO: worth it? cleverer way?
withContext = (name) -> { "#{name}": { unapply: (x, additional) -> if isFunction(x) then x(this.value[0], this.value[1], additional...) else x } }

cases = { recurse, delegate, defer, varying, value, nothing } = defcase('org.janusjs.traversal', (withContext(x) for x in [ 'recurse', 'delegate', 'defer', 'varying', 'value', 'nothing' ])...)
cases2 = {} # external cases set that wraps two args into an array.
for k, kase of cases
  do (kase) -> cases2[k] = (x, context) -> kase([ x, context ])


# util:
get = (obj, k) ->
  if obj.isCollection is true
    obj.at(k)
  else if obj.isStruct is true
    obj.get(k)
isParentValueParent = (obj, k, v) ->
  if obj._parent?
    get(obj._parent, k) is v._parent
  else
    false


# core mechanism:

# TODO: the mechanism of passing state here is far from my favourite. someone
# please come up with something smarter.
matcher = match(
  recurse (into, context, local) -> local.root(into, local.map, context ? local.context, local.reduce)
  delegate (to, context, local) -> matcher(to(local.key, local.value, local.obj, local.attribute, context ? local.context), extendNew(local, { context }))
  defer (to, context, local) -> matcher(to(local.key, local.value, local.obj, local.attribute, context ? local.context), extendNew(local, { context, map: to }))
  varying (v, _, local) ->
    result = v.map((x) -> matcher(x, local))
    result = result.get() if local.immediate is true
    result
  value (x) -> x
  nothing -> undefined
)

# TODO: this is all repetitive but also not? but also i don't want to break it
# into a function maybe because perf?
Traversal =
  asList: (obj, map, context = {}, reduce = identity) ->
    reduce(
      obj.enumeration().flatMapPairs((key, value) ->
        attribute = obj.attribute(key) if obj.isModel is true and obj.isCollection isnt true # this line sucks.
        local = { obj, map, reduce, key, value, attribute, context, root: Traversal.asList }
        matcher(map(key, value, obj, attribute, context), local)
      )
    )

  getArray: (obj, map, context = {}, reduce = identity) ->
    reduce(
      for key in obj.enumerate() 
        value = get(obj, key)
        attribute = obj.attribute(key) if obj.isModel is true and obj.isCollection isnt true # this line still sucks.
        local = { obj, map, reduce, key, value, attribute, context, immediate: true, root: Traversal.getArray }
        matcher(map(key, value, obj, attribute, context), local)
    )


# default impl:

Traversal.default =
  serialize:
    map: (obj, k, v, attribute, context) ->
      if attribute?.serialize?
        value(attribute.serialize())
      else if v?
        if v.isCollection is true or v.isStruct is true
          recurse(v)
        else
          value(v)
      else
        nothing()

  modified:
    map: (obj, k, v, attribute, context) ->
      if !obj._parent?
        value(false)
      else if v?.isStruct is true
        if isParentValueParent(obj, k, v) then recurse(v) else value(true)
      else if v?.isCollection is true
        if isParentValueParent(obj, k, v)
          varying(from(v.watchLength()).and(v._parent.watchLength()).all.plain().map((la, lb) ->
            if la isnt lb then value(true) else recurse(v)
          ))
        else
          value(true)
      else if v?.isVarying is true
        varying(v.map(Traversal.default.modified.map))
      else
        value(obj._parent.get(k) isnt v)
    reduce: (list) -> list.any((x) -> x is true)

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


module.exports = { Traversal, cases: cases2 }

