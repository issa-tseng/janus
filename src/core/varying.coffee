{ isFunction, fix, uniqueId } = require('../util/util')

class Varying
  # flag to enable duck-typed detection of this class. thanks, npm.
  isVarying: true

  constructor: (value) ->
    this.set(value) # immediately set our internal value.
    this._observers = {} # track our observers so we can notify on change.

    this._generation = 0 # keeps track of which propagation cycle we're on.

  map: (f) -> new MappedVarying(this, f)

  flatten: -> new FlattenedVarying(this)

  flatMap: (f) -> new FlatMappedVarying(this, f)

  react: (f_) ->
    # use a unique id and an obj for quicker manifest ops than an array.
    id = uniqueId()
    this._observers[id] = new Varied(id, f_, => delete this._observers[id])

  reactNow: (f_) ->
    varied = this.react(f_)
    f_.call(varied, this.get())
    varied

  set: (value) ->
    return if value is this._value

    generation = this._generation += 1
    this._value = value

    for _, observer of this._observers
      observer.f_(this._value)
      return if generation isnt this._generation # we've re-triggered setValue. abort.

    null

  get: -> this._value

  _pure = (flat) -> (args...) ->
    if isFunction(args[0])
      f = args[0]

      (fix (curry) -> (args) ->
        if args.length < f.length
          (more...) -> curry(args.concat(more))
        else
          new ComposedVarying(args, f, flat)
      )(args.slice(1))
    else
      f = args.pop()
      new ComposedVarying(args, f, flat)

  @pure: _pure(false)

  # Synonym for `pure`, in case it's too haskell-y for people to understand.
  @mapAll: @pure

  @flatMapAll: _pure(true)

  # convenience constructor to ensure a Varying. wraps nonVaryings, and returns
  # Varyings given to it.
  @ly: (x) -> if x?.isVarying is true then x else new Varying(x)

class Varied
  constructor: (@id, @f_, @stop) ->

identity = (x) -> x

class FlatMappedVarying extends Varying
  constructor: (@_parent, @_f = identity, @_flatten = true) ->
    this._observers = {}
    this._refCount = 0

  react: (callback) ->
    self = this

    id = uniqueId()
    this._observers[id] = varied = new Varied(id, callback, =>
      delete this._observers[id]
      parentVaried.stop() # the ref below will get hoisted.
    )

    lastValue = null
    lastInnerVaried = null
    onValue = (value) ->
      return if value is lastValue

      if self._flatten is true and this is parentVaried
        lastInnerVaried?.stop()
        if value?.isVarying is true
          lastInnerVaried = value.reactNow(onValue)
          return # TODO: i despise non-immediate returns.
        else
          lastInnerVaried = null # don't allow .stop() to be called repeatedly.

      callback.call(varied, value)
      lastResult = value

    parentVaried = this._bind(onValue)

    varied

  _bind: (callback) -> varied = this._parent.react((x) => callback.call(varied, this._f.call(null, x)))

  set: null

  get: ->
    result = this._f.call(null, this._parent.get())
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
# So, we always reactNow on our parents, even if we simply are reacted.
class ComposedVarying extends FlatMappedVarying
  constructor: (@_applicants, @_f = identity, @_flatten = false) ->
    this._observers = {}
    this._refCount = 0
    this._partial = []

    this._parentVarieds = []
    this._callbacks = {}

  _bind: (callback) ->
    id = uniqueId()
    varied = new Varied(id, callback, =>
      delete this._observers[id]

      this._refCount -= 1
      v.stop() for v in this._parentVarieds if this._refCount is 0
    )

    if this._refCount is 0
      this._parentVarieds = for a, idx in this._applicants
        do (a, idx) => a.reactNow =>
          this._partial[idx] = a
          o.f_(this._partial) for o in this._observers

    this._refCount += 1
    this._observers.push(varied)
    varied

  get: ->
    result = this._f.apply(null, (a.get() for a in this._applicants))
    if this._flatten is true and result?.isVarying is true
      result.get()
    else
      result

module.exports = { Varying, Varied, FlatMappedVarying, FlattenedVarying, MappedVarying, ComposedVarying }

