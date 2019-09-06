{ Varying } = require('../core/varying')
{ identity, isFunction, deepSet, fix } = require('../util/util')

{ match, otherwise } = require('../core/case')
{ recurse, delegate, defer, varying, value, nothing } = require('../core/types').traversal


# this is the function that (once context is supplied) is fed directly to flatMapPairs
# to actually perform value mapping per data pair.
pair = (fs, recurser, obj, immediate) -> (key, val) ->
  attribute = obj.attribute(key) if obj.isModel is true

  fix((recontext) -> (fs) -> fix((rematch) -> match(
    recurse (into) -> recurser(into, fs)
    delegate (to) -> rematch(to(key, val, obj, attribute))
    defer (to) -> recontext(Object.assign({}, fs, to)) # TODO: filter to obj attrs?
    varying (v) -> if immediate is true then rematch(v.get()) else v.map(rematch)
    value (x) -> x
    nothing -> undefined
  ))(fs.map(key, val, obj, attribute)))(fs)

# entrypoint; called top-level before actually performing the structure traversal, so
# there is a chance at each recursion layer to intervene with some other action.
# only by returning a recurse action (or not defining a recurse func, which returns
# a recurse action) will recursion actually be performed.
root = (traverse) -> (fs, recurser, obj) -> fix((rematch) -> match(
  recurse (into) -> traverse(fs, recurser, into)
  delegate (to) -> rematch(to(obj))
  defer (to) -> root(traverse)(Object.assign({}, fs, to), recurser, obj)
  varying (v) -> v.flatMap(rematch) # flat because Varying.managed if fs.reduce?
  value (x) -> x
  nothing -> undefined
))((fs.recurse ? recurse)(obj))

# generate our two actual root funcs with our two traversal methodologies, for
# use by Traversal.(natural|list); the immediate versions do their own structure work.
naturalRoot = root((fs, recurser, obj) -> obj.flatMapPairs(pair(fs, recurser, obj)))
listRoot = root((fs, recurser, obj) ->
  result = obj.enumerate().flatMapPairs(pair(fs, recurser, obj))
  if fs.reduce? then Varying.managed((-> result), fs.reduce) else result
)

# the actual runners that set state and call into the above. the first two return
# live traversals; the second two just do the work.
Traversal =
  natural: (obj, fs) -> naturalRoot(fs, Traversal.natural, obj)
  list: (obj, fs) -> listRoot(fs, Traversal.list, obj)

  natural_: (obj, fs) ->
    lpair = pair(fs, Traversal.natural_, obj, true)
    if obj.isMappable is true then lpair(key, obj.get_(key)) for key in obj.enumerate_()
    else
      result = {}
      deepSet(result, key)(lpair(key, obj.get_(key))) for key in obj.enumerate_()
      result

  list_: (obj, fs) ->
    lpair = pair(fs, Traversal.list_, obj, true)
    lpair(key, obj.get_(key)) for key in obj.enumerate_()

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
    recurse: ([ oa, ob ]) ->
      if (oa?.isEnumerable is true and ob?.isEnumerable is true) and (oa.isMappable is ob.isMappable)
        varying(Varying.mapAll(oa.length, ob.length, (la, lb) ->
          if la isnt lb then value(true)
          else recurse(oa.flatMapPairs((k, va) -> ob.get(k).map((vb) -> [ va, vb ])))
        ))
      else
        value(new Varying(oa isnt ob))
    map: (k, [ va, vb ], _, attribute) ->
      if va? and vb?
        if (va?.isEnumerable is true and vb?.isEnumerable is true) and (va.isMappable is vb.isMappable)
          recurse([ va, vb ])
        else
          value(va isnt vb)
      else
        value(va? or vb?)
    reduce: (list) -> list.any()

module.exports = { Traversal }

