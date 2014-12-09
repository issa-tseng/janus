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

  @pure: (args...) ->
    if isFunction(args[0])
      f = args[0]

      (fix (curry) -> (args) ->
        if args.length < f.length
          (more...) -> curry(args.concat(more))
        else
          new ComposedVarying(args, f)
      )(args.slice(1))
    else
      f = args.pop()
      new ComposedVarying(args, f)

  # Synonym for `pure`, in case it's too haskell-y for people to understand.
  @mapAll: @pure

  # convenience constructor to ensure a Varying. wraps nonVaryings, and returns
  # Varyings given to it.
  @ly: (x) -> if x?.isVarying is true then x else new Varying(x)

class Varied
  constructor: (@id, @f_, @stop) ->

class FlatMappedVarying extends Varying
  identity = (x) -> x

  constructor: (@_parent, @_f = identity, @_flatten = true) ->
    this._observers = {}

  react: (callback) ->
    self = this

    id = uniqueId()
    this._observers[id] = varied = new Varied(id, callback, =>
      delete this._observers[id]
      parentVaried.stop() # the ref below will get hoisted.
    )

    lastResult = null
    lastInnerVaried = null
    onValue = (value) ->
      result = if this is parentVaried then self._f.call(null, value) else value
      return if result is lastResult

      if self._flatten is true and this is parentVaried
        lastInnerVaried?.stop()
        if result?.isVarying is true
          lastInnerVaried = result.reactNow(onValue)
          return # TODO: i despise non-immediate returns.
        else
          lastInnerVaried = null # don't allow .stop() to be called repeatedly.

      callback.call(varied, result)
      lastResult = result

    parentVaried = this._parent.react(onValue)

    varied

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

class ComposedVarying extends FlatMappedVarying

module.exports = { Varying, Varied, FlatMappedVarying, FlattenedVarying, MappedVarying, ComposedVarying }

