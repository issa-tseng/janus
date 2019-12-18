# **Map**s underly `Model`s, and provide the basic observable hash data
# structure at the core of `Model`.
#
# The only advanced feature it provides is shadowing; there aren't really
# many internal uses for Map that don't also want shadowing, and separating
# that concern results in harder to read, less performant code anyway.

{ Enumerable } = require('./collection')
{ Varying } = require('../core/varying')
{ deepGet, deepSet, deepDelete, isArray, isString, isPlainObject, isEmptyObject, traverse, traverseAll } = require('../util/util')


# sentinel value to record a child-nulled value. instantiate a class instance
# so that it doesn't read as a simple object.
class NothingClass
Nothing = new NothingClass()


# helper that propagates a value change. defined separately because i don't really
# understand js inlining rules and i'm not sure if a method is eligible for inlining.
_changed = (map, key, newValue, oldValue) ->
  oldValue = null if oldValue is Nothing

  # emit events for leaf nodes that no longer exist:
  if isPlainObject(oldValue) and !newValue?
    traverse(oldValue, (path, value) =>
      subkey = "#{key}.#{path.join('.')}"
      map._watches[subkey]?.set(null)
      map.emit('changed', subkey, null, value)
    )

  # now emit direct events:
  map._watches[key]?.set(newValue)
  map.emit('changed', key, newValue, oldValue)
  return


class Map extends Enumerable
  isMap: true

  constructor: (data = {}, @options = {}) ->
    super()

    this.data = {}
    this._watches = {}

    # If we have a designated shadow parent, set it and track its events.
    if this.options.parent?
      this._parent = this.options.parent
      this.listenTo(this._parent, 'changed', (key, newValue, oldValue) => this._parentChanged(key, newValue, oldValue))

    # Allow setup that happens before initial data load occurs, without
    # overriding constructor args.
    this._preinitialize?()

    # Drop in our data.
    this.set(data)

    # Allow setup tasks without overriding+passing along constructor args.
    this._initialize?()

  # Get a data value from this model. The key can be a dot-separated path into
  # a nested plain model. We do not traverse into submodels that have been
  # inflated.
  get_: (key) ->
    value = deepGet(this.data, key)

    # If we don't have a value, maybe our parent does. If it does and it's a
    # Map, we'll want to shadowclone it before returning.
    if !value? and this._parent?
      value = this._parent.get_(key)
      if value?.isEnumerable is true
        value = value.shadow()
        this.set(key, value)

    if value is Nothing then null else value

  # Set a data value on this model. Takes any of:
  # 1. .set(k, v) sets v at k. if v is a plain object. all k/v pairs will be set.
  #                            if v is === null, k will be .unset().
  # 2. .set(obj) sets each k/v pair in obj.
  # 3. .set(k) returns a function (v) -> v that will set v at k.
  set: (x, y) ->
    xIsString = isString(x)
    if xIsString and (y is null)
      this.unset(x)
    else if xIsString and arguments.length is 1 # use arity to check curry (gh#156)
      (y) => this.set(x, y)
    else
      yIsPlainObject = isPlainObject(y)
      if y? and (!yIsPlainObject or isEmptyObject(y))
        this._set(x, y)
      else if yIsPlainObject
        obj = {}
        deepSet(obj, x)(y)
        traverse(obj, (path, value) => this._set(path, value))
      else if isPlainObject(x)
        traverse(x, (path, value) => this._set(path, value))

  # The actual setter for a k/v pair. We isolate this so that after our sorting
  # out of parameters above each k/v pair may be assessed and manipulated by
  # subclasses.
  _set: (key, value) ->
    oldValue = deepGet(this.data, key)
    return if oldValue is value

    deepSet(this.data, key)(value)
    key = key.join('.') if isArray(key)
    _changed(this, key, value, oldValue)
    return

  # Clear the value of some key and returns the cleared value. If we are a shadow
  # copy, we'll actually leave behind a sentinel so that we know not to read into
  # our parent. Fires events as needed.
  unset: (key) ->
    if this._parent?
      oldValue = this.get_(key)
      deepSet(this.data, key)(Nothing)
    else
      oldValue = deepDelete(this.data, key)

    _changed(this, key, this.get_(key), oldValue) if oldValue?
    oldValue

  # Revert a particular data key on this model to its shadow parent, returning
  # the cleared value and firing events as needed. After this, the model will
  # return whatever its parent thinks the value should be. If no parent exists,
  # this function will fail silently. The key can be a dot-separated path.
  revert: (key) ->
    return unless this._parent?

    oldValue = deepDelete(this.data, key)
    newValue = this.get_(key)
    _changed(this, key, newValue, oldValue) unless newValue is oldValue
    oldValue

  # Shadow-copies a model.
  shadow: (klass) -> new (klass ? this.constructor)({}, Object.assign({}, this.options, { parent: this }))

  # Shadow-copies a model, inserting the data given. Really just syntactic sugar
  # which obviates variable assignment in some cases.
  with: (data) ->
    result = this.shadow()
    result.set(data)
    result

  # Returns the original (non-shadow) instance of a model. Can be self.
  original: -> this._parent?.original() ? this

  # Get a `Varying` object for a particular key. Uses events to set. Caches.
  get: (key) ->
    extant = this._watches[key]
    if extant? then return extant
    else # ugh; i dislike having to make this ref; see #145
      v = new Varying(this.get_(key))
      v.__owner = this
      this._watches[key] = v

  # Handles our parent's changes and judiciously vends those events ourselves.
  _parentChanged: (key, newValue, oldValue) ->
    ourValue = deepGet(this.data, key)
    return if ourValue? or ourValue is Nothing # the change doesn't affect us.

    this._watches[key]?.set(newValue)
    this.emit('changed', key, newValue, oldValue)
    return

  # Simple shortcuts.
  values_: -> this.get_(key) for key in this.enumerate_()
  values: -> this.enumerate().flatMap((k) => this.get(k))

  # Maps this map's values onto a new Map, with the same key structure. The
  # mapping functions are passed (key, value) as the arguments.
  mapPairs: (f) ->
    result = new DerivedMap()
    traverse(this.data, (k, v) ->
      k = k.join('.')
      result.__set(k, f(k, v))
    )
    result.listenTo(this, 'changed', (key, value) =>
      if value? and value isnt Nothing
        result.__set(key, f(key, value))
      else
        result._unset(key)
    )
    result

  # Flatmaps this map's values onto a new Map, with the same key structure.
  # The mapping functions are passed (key, value) as the arguments.
  flatMapPairs: (f, klass = DerivedMap) ->
    result = new klass()
    varieds = {}
    add = (key) =>
      varieds[key] ?= this.get(key).flatMap((value) => f(key, value)).react((x) -> result.__set(key, x))
    traverse(this.data, (k) -> add(k.join('.')))

    result.listenTo(this, 'changed', (key, newValue, oldValue) =>
      if newValue? and !varieds[key]?
        # check v[k] rather than oldValue to account for an {} becoming an atom.
        add(key)
      else if oldValue? and !newValue?
        for k, varied of varieds when k.indexOf(key) is 0
          varied.stop()
          delete varieds[k]
        result._unset(key)
    )
    result.on('destroying', -> varied.stop() for _, varied of varieds)
    result

  # Gets the number of k/v pairs in this Map. Depends on enumeration.
  Object.defineProperty(@prototype, 'length', get: -> this.length$ ?= Varying.managed((=> this.enumerate()), (it) -> it.length))
  Object.defineProperty(@prototype, 'length_', get: -> this.enumerate_().length)

  __destroy: ->
    # jettison all likely ties to other objects.
    this._parent = null
    #this.data = null
    this._watches = Nothing

  # Takes in a data hash and populates a new Map (or Map covariant) with its data.
  @deserialize: (data) -> new this(data)


class DerivedMap extends Map
  isDerivedMap: true
  roError = -> throw new Error('this map is read-only')

  for method in [ '_set', 'setAll', 'unset', 'revert' ]
    this.prototype["_#{method}"] = this.__super__[method]
    this.prototype[method] = roError

  set: -> roError
  shadow: -> this


module.exports = { Map, Nothing }

