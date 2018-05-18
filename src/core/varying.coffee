# `Varying` is a monad. Don't worry about the m-word. All it means here is that
# it has facilities to help you handle state, and chaining stateful consequences
# together without sacrificing the functional purity of userland code.
#
# For more philosophy on `Varying`, please see the documentation.
#
# Internally, `Varying` operates as follows:
# * `map` returns a new `Varying`, but all that is really returned is the new
#   monad recording the composition of the existing `Varying` and a pure function.
#   Once the computation is activated, it of course applies the function to the
#   value any time the original value changes, and wraps the result.
# * `flatten` takes a wrapped `Varying` and flattens it down. As with `map`,
#   this is entirely a passive action at first. The one trick with `flatten` is
#   that if the inner value is a `Varying`, the outer one being flattened will
#   itself update to track the inner value.
# * `flatMap` is a composition of the two, but:
#
# `map` and `flatten` are actually implemented in terms of `flatMap`. In fact,
# `flatMap` is implemented in the `FlatMappedVarying` class below. It simply
# has some non-exposed toggles to turn on and off flattening behaviour, and it
# presumes a mapping function of `identity` if not given.
#
# The other tricky implementation detail is `::pure`. This is also largely
# implemented in terms of `flatMap`, for the sake of exposing the same mapping
# and flattening behaviour without duplicating code, but has a different binding
# to its parent, which first gathers all the applicants' values and applies them
# before handing the single value back to the normal `Varying` machinery.
#
# Both bindings, the `Varying` and the `ComposedVarying` implementations cache
# the binding to the parent, and only listen once to them for every map or
# reaction bound outward. We use refcounting to manage this.

{ isFunction, fix, uniqueId } = require('../util/util')


class Varying
  # flag to enable duck-typed detection of this class. thanks, npm.
  isVarying: true

  constructor: (value) ->
    this.set(value) # immediately set our internal value.
    this._observers = {} # track our observers so we can notify on change.
    this._refCount = 0

    this._generation = 0 # keeps track of which propagation cycle we're on.

  # (Varying v) => v a -> (a -> b) -> v b
  map: (f) -> new MappedVarying(this, f)

  # (Varying v) => v v a -> v a
  flatten: -> new FlattenedVarying(this)

  # (Varying v) => v a -> (a -> v b) -> v b
  flatMap: (f) -> new FlatMappedVarying(this, f)

  # returns the `Observation` representing this reaction.
  # (Varying v, Observation w) => v a -> (a -> ()) -> w
  reactLater: (f_) ->
    id = uniqueId()
    this._refCount += 1
    this.refCount$?.set(this._refCount)

    this._observers[id] = new Observation(this, id, f_, =>
      delete this._observers[id]
      this._refCount -= 1
      this.refCount$?.set(this._refCount)
    )

  # (Varying v, Observation w) => v a -> (a -> ()) -> w
  react: (f_) ->
    observation = this.reactLater(f_)
    f_.call(observation, this.get())
    observation

  # gets and stores a value, and triggers any reactions upon it. returns nothing.
  # impure! (Varying v) => v a -> b -> ()
  set: (value) ->
    return if value is this._value

    generation = this._generation += 1
    this._value = value

    for _, observer of this._observers
      observer.f_(this._value)
      return if generation isnt this._generation # we've re-triggered setValue. abort.

    null

  # (Varying v) => v a -> a
  get: -> this._value

  # simple chaining tool to allow eg myvarying.pipe(throttle(50)), which is easier to
  # read in a chain order than throttle(50, myvarying).
  # (Varying v, Any w) => v a -> (v b -> w b) -> w b
  pipe: (f) -> f(this)

  # (Varying v, Int b) => v a -> v b
  refCount: -> this.refCount$ ?= new Varying(this._refCount)

  # forever binds this varying to the value of another.
  # TODO: is this absolutely awful? maybe.
  # TODO: this is confusingly named next to _bind, as they are not related, but
  #       _bind is internal so we'll ignore it for now.
  bind: (other) ->
    (this[k] = v) for k, v of FlatMappedVarying.prototype
    FlatMappedVarying.call(this, other)

  # we have two very similar behaviours, `pure` and `flatMapAll`, that differ only
  # in a parameter passed to the returned class. so we implement it once and
  # partially apply with that difference immedatiely.
  _pure = (flat) -> (args...) ->
    if isFunction(args[0]) and not args[0].react?
      f = args[0]

      (fix (curry) -> (args) ->
        if args.length < f.length
          (more...) -> curry(args.concat(more))
        else
          new ComposedVarying(args, f, flat)
      )(args.slice(1))
    else # TODO: can't we curry here too until we see a function?
      f = args.pop()
      new ComposedVarying(args, f, flat)

  # overloaded, flexible argument count a/b/c/d/etc:
  # (Varying v) => (a -> b -> c) -> v a -> v b -> v c
  # (Varying v) => v a -> v b -> (a -> b -> c) -> v c
  @pure: _pure(false)

  # Synonym for `pure`, in case it's too haskell-y for people to understand.
  @mapAll: @pure

  # overloaded, flexible argument count a/b/c/d/etc:
  # (Varying v) => (a -> b -> v c) -> v a -> v b -> v c
  # (Varying v) => v a -> v b -> (a -> b -> v c) -> v c
  @flatMapAll: _pure(true)

  # simple lift operation for a pure function:
  # (Varying v) => (a -> b -> c) -> v a -> v b -> v c
  @lift: (f) -> (args...) -> new ComposedVarying(args, f, false)

  @managed: (resources..., computation) -> new ManagedVarying(resources, computation)

  # convenience constructor to ensure a Varying. wraps nonVaryings, and returns
  # Varyings given to it.
  # (Varying v) => a -> v a
  @ly: (x) -> if x?.isVarying is true then x else new Varying(x)

class Observation
  constructor: (@parent, @id, @f_, @_stop) ->
  stop: ->
    this.stopped = true # for debugging.
    this._stop()

identity = (x) -> x
nothing = { isNothing: true }

class FlatMappedVarying extends Varying
  constructor: (@_parent, @_f = identity, @_flatten = true) ->
    this._observers = {}
    this._refCount = 0
    this._value = nothing

  # with the normal Varying, we simply react and call get() for the immediate
  # callback. this gets really tricky with flatten, because an extant Varying won't
  # be correctly bound to with that method when react gets called. so we override
  # the default implementation and parameterize _react to handle it internally if
  # necessary.
  react: (f_) -> this._react(f_, true)
  reactLater: (f_) -> this._react(f_, false)

  _react: (callback, immediate) ->
    # create the consumer Observation that will be returned.
    id = uniqueId()
    this._observers[id] = observation = new Observation(this, id, callback, =>
      delete this._observers[id]

      this._refCount -= 1
      if this._refCount is 0
        this._lastInnerObservation?.stop()
        this._parentObservation.stop()
        this._value = nothing
      this.refCount$?.set(this._refCount)
    )

    # track our own refcount, an only bind upwards once on initial requirement.
    if this._refCount is 0
      this._lastInnerObservation = null
      this._generation = 0
      this._parentObservation = this._bind() 

    # increment and update refcount only after we've bound, but before we call
    # immediate in case we have eg a managed varying.
    initialGeneration = this._generation
    this._refCount += 1
    this.refCount$?.set(this._refCount)

    # the only cases we can ignore the initial value are nonflat nonimmediates,
    # or if someone has already fired our bound listener within refcount.
    if (this._generation is initialGeneration) and (this._flatten is true or immediate is true)
      if this._value is nothing
        this._onValue(this._parentObservation, this._immediate(), !immediate)
      else if immediate is true
        callback.call(observation, this._value)

    observation

  # onValue is the handler called for both the parent changing _as well as_
  # an inner flattened value changing. it is called _after_ any value-mapping
  # is performed.
  _onValue: (observation, value, silent = false) ->
    self = this

    if this._flatten is true and observation is this._parentObservation
      # unbind old and bind to new if applicable.
      this._lastInnerObservation?.stop()
      if value?.isVarying is true
        this._lastInnerObservation = value.react((raw) -> self._onValue(this, raw, silent))
        silent = false # don't like this line repetition but it's necessary due to early return.
        return # don't run the below, since react will update the value.
      else
        this._lastInnerObservation = null

    if (value isnt this._value) and (silent isnt true)
      # we always call onValue immediately; so we don't want to notify if
      # this is our first trip and immediate is false.
      generation = (this._generation += 1)
      o.f_(value) for _, o of this._observers when generation is this._generation

    this._value = value
    silent = false
    null

  # actually listens to the parent(s) and returns the Observation that represents it.
  #
  # mapping is handled here because the implementation of applying it varies depending
  # on whether there is one parent or many.
  _bind: -> this._parent.reactLater((raw) => this._onValue(this._parentObservation, this._f.call(null, raw)))

  # used internally; essentially get() w/out flatten.
  _immediate: ->
    if this._value is nothing
      this._f.call(null, this._parent.get())
    else
      this._value

  # can't set a derived varying.
  set: undefined
  bind: undefined

  # gets immediate, then flattens if we should.
  get: ->
    result = this._immediate()
    if this._flatten is true and result?.isVarying is true
      result.get()
    else
      result

class FlattenedVarying extends FlatMappedVarying
  constructor: (parent) -> super(parent)

class MappedVarying extends FlatMappedVarying
  constructor: (parent, f) -> super(parent, f, false)


# ComposedVarying has some odd implications. It's not valid to apply our map
# without all the values present, and trying to fulfill that kind of interface
# leads to huge oddities with side effects and call orders.
# So, we always react on our parents, even if we simply are reactLatered.
class ComposedVarying extends FlatMappedVarying
  constructor: (@_applicants, @_f = identity, @_flatten = false) ->
    this._observers = {}
    this._refCount = 0
    this._value = nothing
    this._allBound = false

    this._partial = [] # track the current mapping arguments.
    this._parentObservations = [] # track our observers watching for mapping arguments.

  # as noted above, we reimplement here because there are many parents, and we
  # have to implement the mapping application differently.
  _bind: ->
    # listen to all our parents if we must.
    this._parentObservations = for a, idx in this._applicants
      do (a, idx) => a.react((value) =>
        # update our arguments list, then trigger internal observers in turn.
        # note that this doesn't happen for the very first call, since internal
        # observers is not updated until the end of this method.
        this._partial[idx] = value
        this._onValue(this._parentObservation, this._f.apply(this._parentObservations[idx], this._partial)) if this._allBound is true
        null
      )

    # release lock on callback firing and return an agglomerated observation.
    this._allBound = true
    new Observation(this, uniqueId(), null, => v.stop() for v in this._parentObservations)

  _immediate: ->
    if this._value is nothing
      if this._allBound is true
        this._f.apply(null, this._partial)
      else
        this._f.apply(null, (a.get() for a in this._applicants))
    else
      this._value

class ManagedVarying extends FlatMappedVarying
  constructor: (@_resources, @_computation) ->
    super(new Varying())

    this._awake = false
    resources = null
    this.refCount().reactLater((count) =>
      if count > 0 and this._awake is false
        this._awake = true
        resources = (f() for f in this._resources)
        this._parent.set(this._computation.apply(null, resources))
      else if count is 0 and this._awake is true
        this._awake = false
        resource.destroy() for resource in resources
    )

  get: ->
    if this._awake is true
      super()
    else
      result = null
      this.react((x) -> result = x; this.stop()) # kind of gross? but maybe not?
      result


module.exports = { Varying, Observation, FlatMappedVarying, FlattenedVarying, MappedVarying, ComposedVarying }

