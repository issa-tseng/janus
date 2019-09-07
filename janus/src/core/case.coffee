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

{ isPlainObject, isString, capitalize, identity } = require('../util/util')

class Case
  isCaseInstance: true
  constructor: (@_value) ->
  get: -> this._value
  map: (f) -> new this.constructor(f(this._value))
  toString: -> "case[#{this.name}]: #{this._value}"

# used to decorate ctors below:
singleMatch = (type) -> (x, f_) ->
  if f_?
    if x instanceof type then f_(x._value)
  else x instanceof type

# reduce boilerplate in fullDefcase below:
deftype = (base, name, abstract) -> class extends base
  abstract: abstract
  name: name

# the bulk of the work is here, defining the case set.
defcase = (args...) ->
  types = {}
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
          recurse(v, (types[k] = deftype(localBase, k, true)))
    return
  recurse(args, base)

  # create a constructor for each type, with some decoration:
  ctors = {}
  for name, type of types
    ctors[name] = ctor = ((T) -> (x) -> new T(x))(type)
    Object.assign(ctor, { isCase: true, type, match: singleMatch(type) })

  # decorate methods now that we have the full type and ctors set:
  for name, type of types when type.prototype.abstract isnt true
    Name = capitalize(name) # still just a string but name/Name reflect cap'z'n
    self = -> this

    base.prototype["#{name}OrElse"] = identity
    type.prototype["#{name}OrElse"] = Case.prototype.get

    base.prototype["get#{Name}"] = self
    type.prototype["get#{Name}"] = Case.prototype.get

    base.prototype["map#{Name}"] = self
    type.prototype["map#{Name}"] = Case.prototype.map

  # hand back the constructors only.
  ctors

# form the final output builder (defaults to no options):
Case.build = defcase

# matches anything, but will return the case itself.
class Otherwise
  constructor: (@_f) ->
otherwise = (f) -> new Otherwise(f)

# runs through conditions until one matches, or use otherwise.
match = (conds...) -> (kase) ->
  return if kase?.abstract is true
  for cond in conds
    return cond._value(kase._value) if kase instanceof cond.constructor
    return cond._f(kase) if cond instanceof Otherwise
  return

module.exports = { Case, match, otherwise }

