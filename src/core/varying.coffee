# `Varying` is a monad. Don't worry about the m-word. All it means here is that
# it has facilities to help you handle state, and chaining stateful consequences
# together without sacrificing the functional purity of userland code.

{ isFunction, fix, uniqueId, identity } = require('../util/util')


################################################################################
# UTIL FUNCTIONS/OBJECTS

noop = (->)
nothing = { isNothing: true }

# some specialized methods that get decorated in upon dependent construction:
stopOne = ->
  this._value = nothing
  this._inner?.stop()
  this._inner = null
  this._applicantObs[0].stop()
  return
stopAll = ->
  this._value = nothing
  this._inner?.stop()
  this._inner = null
  ao.stop() for ao in this._applicantObs
  return

# cheat the jit. also we use this odd this.a namings scheme to cheat the minifier.
apply = [
  -> noop # nonsensical
  -> noop # extra-specialized
  (f, x) -> a = x[0]; b = x[1]; -> f(a._value, b._value)
  (f, x) -> a = x[0]; b = x[1]; c = x[2]; -> f(a._value, b._value, c._value)
  (f, x) ->
    a = x[0]; b = x[1]; c = x[2]; d = x[3]
    -> f(a._value, b._value, c._value, d._value)
  (f, x) ->
    a = x[0]; b = x[1]; c = x[2]; d = x[3]; e = x[4]
    -> f(a._value, b._value, c._value, d._value, e._value)
  (f, x) ->
    a = x[0]; b = x[1]; c = x[2]; d = x[3]; e = x[4]; m = x[5]
    -> f(a._value, b._value, c._value, d._value, e._value, m._value)
  (f, x) ->
    a = x[0]; b = x[1]; c = x[2]; d = x[3]; e = x[4]; m = x[5]; n = x[6]
    -> f(a._value, b._value, c._value, d._value, e._value, m._value, n._value)
  (f, x) ->
    a = x[0]; b = x[1]; c = x[2]; d = x[3]; e = x[4]; m = x[5]; n = x[6]; o = x[7]
    -> f(a._value, b._value, c._value, d._value, e._value, m._value, n._value, o._value)
  (f, x) ->
    a = x[0]; b = x[1]; c = x[2]; d = x[3]; e = x[4]; m = x[5]; n = x[6]; o = x[7]; p = x[8]
    -> f(a._value, b._value, c._value, d._value, e._value, m._value, n._value, o._value, p._value)
]


class Observation
  constructor: (@parent, @id, @f_, @_stop) ->
  stop: ->
    return if this.stopped is true
    this.stopped = true # for debugging.
    this._stop()
    return


################################################################################
# BASE VARYING

class Varying
  # flag to enable duck-typed detection of this class.
  isVarying: true
  _refCount: 0 # tracks observer count.
  _generation: 0 # prevents reaction stale-repropagation loops.

  constructor: (value) ->
    this.set(value) # immediately set our internal value.
    this._observers = {} # track our observers so we can notify on change.

  map: (f) -> new MappedVarying(this, f)
  flatten: -> new FlattenedVarying(this)
  flatMap: (f) -> new FlatMappedVarying(this, f)

  _react: (f_ = noop) ->
    id = uniqueId()
    this._refCount += 1
    this.refCount$?.set(this._refCount)

    this._observers[id] = new Observation(this, id, f_, =>
      delete this._observers[id]
      this._refCount -= 1
      this.refCount$?.set(this._refCount)
    )

  _reactImmediate: (f_) ->
    observation = this._react(f_)
    f_?.call(observation, this._value)
    observation

  # interface method which sorts out whether the first arg is an immediate flag
  # or not, and passes along to the appropriate internal methods.
  react: (x, y) ->
    if x is false
      this._react(y)
    else if x is true
      this._reactImmediate(y)
    else
      this._reactImmediate(x)

  # gets and stores a value, and triggers any reactions upon it. returns nothing.
  set: (value) ->
    return if this._value is value
    this._value = value
    this._propagate()
    return

  # sends out the current value to all observers.
  _propagate: ->
    generation = this._generation += 1

    for _, observer of this._observers
      observer.f_(this._value)
      return if generation isnt this._generation # we've re-triggered setValue. abort.
    return

  get: -> this._value

  # simple chaining tool to allow eg myvarying.pipe(throttle(50)), which is easier to
  # read in a chain order than throttle(50, myvarying).
  pipe: (f) -> f(this)

  # we don't manage a Varying with the refcount unless someone asks for it. otherwise
  # we just use the internal prop. here we memoize that refcount varying.
  refCount: -> this.refCount$ ?= new Varying(this._refCount)

  # we have two very similar behaviours, `flatMap` and `flatMapAll`, that differ
  # only in a parameter passed to the returned class. so we implement it once
  # and partially apply with that difference immedatiely.
  _mapAll = (flat) -> (args...) ->
    if isFunction(args[0])
      f = args[0]

      (fix (curry) -> (args) ->
        if args.length < f.length
          (more...) -> curry(args.concat(more))
        else
          new ReducingVarying(args, f, flat)
      )(args.slice(1))
    else
      if isFunction(args[args.length - 1])
        f = args.pop()
        new ReducingVarying(args, f, flat)
      else
        (more...) -> _mapAll(flat)(args.concat(more)...)

  # overloaded, flexible argument count a/b/c/d/etc:
  # (Varying v) => (a -> b -> c) -> v a -> v b -> v c
  # (Varying v) => v a -> v b -> (a -> b -> c) -> v c
  @mapAll: _mapAll(false)

  # overloaded, flexible argument count a/b/c/d/etc:
  # (Varying v) => (a -> b -> v c) -> v a -> v b -> v c
  # (Varying v) => v a -> v b -> (a -> b -> v c) -> v c
  @flatMapAll: _mapAll(true)

  # gives an UnreducedVarying given an array of varyings. it can then be
  # map/flatMap/reacted on as needed.
  @all: (vs) -> new UnreducedVarying(vs)

  # simple lift operation for a pure function:
  # (Varying v) => (a -> b -> c) -> v a -> v b -> v c
  @lift: (f) -> (args...) -> new ReducingVarying(args, f, false)

  # Resource management based on refCount. See ManagedVarying impl below for details.
  @managed: (resources..., computation) -> new ManagedVarying(resources, computation)

  # convenience constructor to ensure a Varying. wraps nonVaryings, and returns
  # Varyings given to it.
  @of: (x) -> if x?.isVarying is true then x else new Varying(x)

  # alias for the constructor, in case people don't like the new syntax.
  @box: (x) -> new Varying(x)


################################################################################
# DERIVED VARYINGS

# This is the base class for all nonprimitive Varyings: single- and multi-input,
# flattened, mapped, and all the combinations therein.
class DerivedVarying extends Varying

  constructor: (applicants, _f = identity, @_flatten = false) ->
    # store instance vars.
    this.a = applicants
    this._f = _f

    # set up default values.
    this._observers = {}
    this._value = nothing

    # specialize some methods based on arity.
    length = applicants.length
    this._apply =
      if length is 1 then first = this.a[0]; -> _f(first._value)
      else if length < 10 then apply[this.a.length](_f, this.a)
      else -> _f((a._value for a in applicants)...)
    this._stop = if length is 1 then stopOne else stopAll

  # uses our cached _value if it ought to be valid; otherwise does the necessary
  # computation on the spot. not fast, of course.
  get: ->
    if this._refCount > 0
      this._value
    else
      result = this._f.apply(null, (a.get() for a in this.a))
      if (this._flatten is true) and (result?.isVarying is true)
        result.get()
      else
        result

  set: undefined # disallow!

  _react: (f_ = noop) ->
    # first react upwards if necessary (first reaction) to force values, then
    # immediately recompute to force our own.
    if this._refCount is 0
      recompute = this._recompute.bind(this, false)
      this._applicantObs = (a.react(false, recompute) for a in this.a)
      this._recompute(true)

    # then update our refCount.
    this._refCount += 1
    this.refCount$?.set(this._refCount)

    # now generate an observation and return it.
    id = uniqueId()
    this._observers[id] = new Observation(this, id, f_, =>
      delete this._observers[id]

      this._refCount -= 1
      this._stop() if this._refCount is 0
      this.refCount$?.set(this._refCount)
    )

  _recompute: (silent = false) ->
    # figure out our current value, bail (carefully: gh53) if it hasn't changed.
    value = this._apply()
    if value is this._value
      if this._inner?
        this._inner.stop()
        this._inner = null
      return

    if this._flatten is true
      # deal with flattening messiness:
      this._inner?.stop()
      if value?.isVarying is true
        first = true
        this._inner = value.react((ival) =>
          return if this._value is ival
          this._value = ival
          this._propagate() unless first is true
        )
        first = false
      else
        this._inner = null
        this._value = value
    else
      # or else just save the value.
      this._value = value

    # now propagate if we ought to.
    this._propagate() unless silent is true
    return

class MappedVarying extends DerivedVarying
  constructor: (parent, f) -> super([ parent ], f, false)
class FlatMappedVarying extends DerivedVarying
  constructor: (parent, f) -> super([ parent ], f, true)
class FlattenedVarying extends DerivedVarying
  constructor: (parent, f) -> super([ parent ], null, true)
class ReducingVarying extends DerivedVarying
  constructor: (parents, f, flat) -> super(parents, f, flat)


# ReducingVarying is limited in that it is bound to a reducing function that takes
# the total arity back to 1 in order to exist. It will almost always be the case
# that such a function exists to do useful work (eg using a mutator), but having
# an artifact that isn't bound allows that reducer definition to be deferred, and
# we also gain a simple way to react directly on multiple Varyings.
#
# This one is a bit internally unique in that its value is almost entirely
# irrelevant; we produce an array to fulfill the contract but map/flatMap shunt
# to ReducingVarying and react is valueless.
class UnreducedVarying extends DerivedVarying
  constructor: (@a) ->
    # set up the bare minimum.
    this._observers = {}
    this._value = nothing

  map: (f) -> new ReducingVarying(this.a, f)
  flatMap: (f) -> new ReducingVarying(this.a, f, true)
  flatten: undefined # doesn't make sense.

  # similar to DerivedVarying, we use our cached value if it exists.
  # but we have to return an array rather than apply args to map.
  get: ->
    if this._refCount > 0 then this._value
    else (a.get() for a in this.a)

  # these methods are typically decorated upon construction to specialize based
  # on arity. eventually maybe we specialize these too but for now just loop.
  #
  # (a side effect of not overriding _recompute is that every _apply() is a new
  # array instance so it'll never deduplicate. but we can't map changed inputs
  # to the same output so duplicates are impossible: if an input has changed the
  # we have changed.)
  _apply: -> (a._value for a in this.a)
  _stop: stopAll

  # patch into these inherited methods to handle the multiple arguments that
  # we have correctly.
  _propagate: ->
    generation = this._generation += 1

    for _, observer of this._observers
      observer.f_.apply(observer, this._value)
      return if generation isnt this._generation # abort on repropagate.
    return
  _reactImmediate: (f_) ->
    observation = this._react(f_)
    f_?.apply(observation, this._value)
    observation


# only when a ManagedVarying is actually reacted upon will it marshall the
# declared dependency resources given at construction-time. and vice versa:
# destroys resources if the Varying goes dormant.
class ManagedVarying extends FlattenedVarying
  constructor: (@_resources, @_computation) ->
    inner = new Varying()
    super(inner)

    this._awake = false
    resources = null
    this.refCount().react(false, (count) =>
      if count > 0 and this._awake is false
        this._awake = true
        resources = (f() for f in this._resources)
        inner.set(this._computation.apply(null, resources))
      else if count is 0 and this._awake is true
        this._awake = false
        resource.destroy() for resource in resources
    )

  get: ->
    if this._awake is true
      super()
    else
      result = null
      resources = (f() for f in this._resources)
      result = this._computation.apply(null, resources).get()
      resource.destroy() for resource in resources
      result


module.exports = { Varying, Observation, FlatMappedVarying, FlattenedVarying, MappedVarying, ReducingVarying }

