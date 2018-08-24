# case.coffee -- case classes for the poor.
#
#
# So, in many cases one wants to encode a type of result and an inner value of
# the result. Because this isn't Scala, one cannot simply use case classes. So,
# we (grumble grumble) roll our own. I hate how wheel-reinventy this is. But it
# really helps with extensibility and inversion of control, so we have it.
#
# For a while we avoided instanceof for this mechanism because peerDependencies
# can get annoying, but instanceof is fast and strcmp is heavy and slow.
#
# We aim to be fairly flexible as to the nature of the value storage. Because we
# have no true pattern-matching and all matches are done purely on the container
# case class type, the value itself may be a black box. So rather than store a
# value, we store an unapply function which can be fed a function to forward its
# data into. This allows multi-arity or custom value expressions. But we do
# still need to get the original first argument due to our reuse of the same
# case construction term as part of the matching syntax.
#
# However, in any configuration other than 1-arity default, case loses its last
# monadic vestiges (we haven't yet done flatten), because the box no longer
# understands how to rebox after operations like map, in particular because map
# only ever returns arity-1. So .map() is performed as a functional composition
# post-unapply which necessarily reduces down to a single return value. Subsequent
# maps will only receive that mapped result.

{ isPlainObject, isString, isArray, isFunction, capitalize, identity } = require('../util/util')

class Case
  isCaseInstance: true
  constructor: (@x1, @unapply) ->
  map: (f) -> new this.constructor(undefined, (g) => g(this.unapply(f)))
  toString: -> "case[#{this.name}]: #{this.x1}"

# used to decorate ctors below:
singleMatch = (type) -> (x, f_) ->
  if f_?
    if x instanceof type then x.unapply(f_)
  else x instanceof type

# use these by default given arity === idx.
defaultUnapplies = [
  (kase) -> (x1) -> new kase(x1, (f) -> f())
  (kase) -> (x1) -> new kase(x1, (f) -> f(x1))
  (kase) -> (x1, x2) -> new kase(x1, (f) -> f(x1, x2))
  (kase) -> (x1, x2, x3) -> new kase(x1, (f) -> f(x1, x2, x3))
]

# reduce boilerplate in fullDefcase below:
deftype = (base, name, abstract) -> class extends base
  abstract: abstract
  name: name

# the bulk of the work is here, defining the case set.
defaultOptions = { arity: 1 }
fullDefcase = (options) -> (args...) ->
  options = Object.assign({}, defaultOptions, options)

  types = {}
  unapplies = {}
  base = class extends Case
    types: types

  # first, retree everything into classtypes and detree into types obj.
  recurse = (xs, localBase) ->
    for x in xs
      if isString(x) # x is just a type name.
        types[x] = deftype(localBase, x, false)
      else # x is an object with k/v pairs defining types.
        for k, v of x
          v = [ v ] if isPlainObject(v) # allow {} or [] nesting.

          if isArray(v) # k: [ ..child types.. ]
            recurse(v, (types[k] = deftype(localBase, k, true)))
          else # k: unapply func.
            unapplies[k] = v
            types[k] = deftype(localBase, k, false)
    return
  recurse(args, base)

  # create a constructor for each type, with some decoration:
  ctors = {}
  for name, type of types
    ctors[name] = ctor =
      if unapplies[name]? then unapplies[name](type)
      else defaultUnapplies[options.arity](type)
    Object.assign(ctor, { isCase: true, type, match: singleMatch(type) })

  # decorate methods now that we have the full type and ctors set:
  for name, type of types when type.prototype.abstract isnt true
    Name = capitalize(name) # still just a string but name/Name reflect cap'z'n
    self = -> this
    typeArity = ctors[name].length
    getter =
      if typeArity is 0 then (->)
      else if typeArity is 1 then -> this.unapply(identity)
      else -> this.unapply((xs...) -> xs)

    base.prototype.get = getter

    base.prototype["#{name}OrElse"] = identity
    type.prototype["#{name}OrElse"] = getter

    base.prototype["get#{Name}"] = self
    type.prototype["get#{Name}"] = getter

    base.prototype["map#{Name}"] = self
    type.prototype["map#{Name}"] = Case.prototype.map

  # hand back the constructors only.
  ctors

# form the final output defcase (defaults to no options):
defcase = fullDefcase()
defcase.withOptions = fullDefcase

# matches anything, but will not unapply; returns the case itself.
class Otherwise
  constructor: (@x1) ->
otherwise = (x1) -> new Otherwise(x1)

# runs through conditions until one matches, or use otherwise.
match = (conds...) -> (kase) ->
  return if kase?.abstract is true
  for cond in conds
    return kase.unapply(cond.x1) if kase instanceof cond.constructor
    return cond.x1(kase) if cond instanceof Otherwise
  return

module.exports = { defcase, match, otherwise }

