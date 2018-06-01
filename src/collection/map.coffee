# **Map**s underly `Model`s, and provide the basic observable hash data
# structure at the core of `Model`.
#
# The only advanced feature it provides is shadowing; there aren't really
# many internal uses for Map that don't also want shadowing, and separating
# that concern results in harder to read, less performant code anyway.

{ Enumerable } = require('./collection')
{ Varying } = require('../core/varying')
{ deepGet, deepSet, deepDelete, extendNew, isArray, isString, isPlainObject, isEmptyObject, traverse, traverseAll } = require('../util/util')


# sentinel value to record a child-nulled value. instantiate a class instance
# so that it doesn't read as a simple object.
class NullClass
Null = new NullClass()

class Map extends Enumerable
  isMap: true

  constructor: (data = {}, @options = {}) ->
    super()

    this.data = {}
    this._watches = {}

    # If we have a designated shadow parent, set it and track its events.
    if this.options.parent?
      this._parent = this.options.parent
      this.listenTo(this._parent, 'anyChanged', (key, newValue, oldValue) => this._parentChanged(key, newValue, oldValue))

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
  #
  # **Returns** the value of the given key.
  get: (key) ->
    value = deepGet(this.data, key)

    # If we don't have a value, maybe our parent does. If it does and it's a
    # Map, we'll want to shadowclone it before returning.
    if !value? and this._parent?
      value = this._parent.get(key)
      if value?.isEnumerable is true
        value = this.set(key, value.shadow())

    if value is Null then null else value

  # Set a data value on this model. Takes two forms:
  #
  # 1. Two fixed parameters. As with get, the first parameter is a dot-separated
  #    string key. The second parameter is the value to set.
  # 2. A hash. It can be deeply nested, but submodels aren't dealt with
  #    specially.
  #
  # Does nothing if the given value is no different from the current.
  #
  # **Returns** the value that was set.
  set: (x, y) ->
    if isString(x) and !y?
      (y) => this._set(x, y)
    else if y? and (!isPlainObject(y) or isEmptyObject(y))
      this._set(x, y)
    else if isPlainObject(y)
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
    return value if oldValue is value

    deepSet(this.data, key)(value)
    key = key.join('.') if isArray(key)
    this._changed(key, value, oldValue)

    value

  # Takes an entire data bag, and replaces our own data with it.
  # Will fire the appropriate events.
  #
  # **Returns** nothing.
  setAll: (attrs) ->
    # first clear off data values that are about to no longer exist, then write over.
    traverseAll(this.data, (path, value) =>
      this.unset(path.join('.')) unless deepGet(attrs, path)?
    )
    this.set(attrs)

    null

  # Clear the value of some key. If we are a shadow copy, we'll actually
  # leave behind a sentinel so that we know not to read into our parent.
  #
  # If the value has changed as a result of this operation, a change event will
  # be issued.
  #
  # **Returns** the value that was cleared.
  unset: (key) ->
    if this._parent?
      oldValue = this.get(key)
      deepSet(this.data, key)(Null)
    else
      oldValue = deepDelete(this.data, key)

    this._changed(key, this.get(key), oldValue) if oldValue?
    oldValue

  # Revert a particular data key on this model. After this, the model will
  # return whatever its parent thinks the value should be. If no parent exists,
  # this function will fail silently. The key can be a dot-separated path.
  #
  # If the value has changed as a result of this operation, a change event will
  # be issued.
  #
  # **Returns** the value that was cleared.
  revert: (key) ->
    return unless this._parent?

    oldValue = deepDelete(this.data, key)
    newValue = this.get(key)
    this._changed(key, newValue, oldValue) unless newValue is oldValue

    oldValue

  # Shadow-copies a model. This allows a second copy of the model to function
  # as its own model instance and keep a separate set of changes, but which
  # will fall back on the original model if asked about a key it doesn't
  # know about.
  #
  # **Returns** a new shadow copy, which is an instance of `Model`.
  shadow: (klass) -> new (klass ? this.constructor)({}, extendNew(this.options, { parent: this }))

  # Shadow-copies a model, inserting the data given. Really just syntactic sugar.
  #
  # **Returns** a new shadow copy with added data.
  with: (data) ->
    result = this.shadow()
    result.set(data)
    result

  # Returns the original copy of a model. Returns itself if it's already an
  # original model.
  #
  # **Returns** an instance of `Model`.
  original: -> this._parent?.original() ? this

  # Get a `Varying` object for a particular key. This simply creates a new
  # Varying that points at our key.
  #
  # **Returns** a `Varying` object against our value at `key`.
  watch: (key) ->
    this._watches[key] ?= do =>
      varying = new Varying(this.get(key))
      this.listenTo(this, "changed:#{key}", (newValue) -> varying.set(newValue))
      varying

  # Helper to generate change events.
  _changed: (key, newValue, oldValue) ->
    oldValue = null if oldValue is Null

    # emit events for leaf nodes that no longer exist:
    if isPlainObject(oldValue) and !newValue?
      traverse(oldValue, (path, value) =>
        subkey = "#{key}.#{path.join('.')}"
        this.emit("changed:#{subkey}", null, value)
        this.emit('anyChanged', subkey, null, value)
      )

    # now emit direct events:
    this.emit("changed:#{key}", newValue, oldValue)
    this.emit('anyChanged', key, newValue, oldValue)

    null

  # Handles our parent's changes and judiciously vends those events ourselves.
  _parentChanged: (key, newValue, oldValue) ->
    ourValue = deepGet(this.data, key)
    return if ourValue? or ourValue is Null # the change doesn't affect us.

    this.emit("changed:#{key}", newValue, oldValue)
    this.emit('anyChanged', key, newValue, oldValue)

  # Maps this map's values onto a new one, with the same key structure. The
  # mapping functions are passed (key, value) as the arguments.
  #
  # **Returns** a new Map.
  mapPairs: (f) ->
    result = new DerivedMap()
    traverse(this.data, (k, v) ->
      k = k.join('.')
      result.__set(k, f(k, v))
    )
    result.listenTo(this, 'anyChanged', (key, value) =>
      if value? and value isnt Null
        result.__set(key, f(key, value))
      else
        result._unset(key)
    )
    result

  # Flatmaps this map's values onto a new one, with the same key structure.
  # The mapping functions are passed (key, value) as the arguments.
  #
  # **Returns** a new Map.
  flatMapPairs: (f, klass = DerivedMap) ->
    result = new klass()
    varieds = {}
    add = (key) =>
      varieds[key] ?= this.watch(key).flatMap((value) => f(key, value)).react((x) -> result.__set(key, x))
    traverse(this.data, (k) -> add(k.join('.')))

    result.listenTo(this, 'anyChanged', (key, newValue, oldValue) =>
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
  watchLength: -> this.watchLength$ ?= Varying.managed((=> this.enumeration()), (it) -> it.watchLength())

  # Takes in a data hash and populates a new Map with its data.
  #
  # **Returns** a `Map` or subclass of `Map`, depending on invocation, with
  # the data populated.
  @deserialize: (data) -> new this(data)


class DerivedMap extends Map
  roError = -> throw new Error('this map is read-only')

  for method in [ '_set', 'setAll', 'unset', 'revert' ]
    this.prototype["_#{method}"] = this.__super__[method]
    this.prototype[method] = roError

  set: -> roError
  shadow: -> this


module.exports = { Null, Map }

