# An Enumeration can be attached to or run against a Struct. It allows live- or
# static- traversal of that Struct, respectively.
#
# Enumerations are separate from Structs and not a derivation or inherent feature
# so that they are only instantiated and incur overhead cost when actually needed,
# and because enumeration behaviour options like shadow-flattening and deep traversal
# can be chosen at will.

{ Varying } = require('../core/varying')
{ DerivedList } = require('../collection/list')
{ Struct } = require('./struct')
{ traverse, traverseAll, deepGet } = require('../util/util')

class KeyList extends DerivedList
  constructor: (@struct, options = {}) ->
    super()
    this.scope = options.scope ? 'all'
    this.include = options.include ? 'values'

    # it's faster to check an object than call indexOf all the time.
    this._trackedKeys = {}

    # add initial keys.
    scanStruct = (struct) => traverse(struct.attributes, (key) => this._addKey(key.join('.')))
    if this.scope is 'all'
      ptr = this.struct
      while ptr?
        scanStruct(ptr)
        ptr = ptr._parent
    else if this.scope is 'direct'
      scanStruct(this.struct)

    # listen for future keys.
    this.listenTo(this.struct, 'anyChanged', (key, newValue, oldValue) =>
      if this.scope is 'direct'
        # TODO: is there a cleverer way to do this?
        ownValue = deepGet(this.struct.attributes, key)
        return if ownValue isnt newValue

      if newValue? and not oldValue?
        this._addKey(key)
      else if oldValue? and not newValue?
        this._removeKey(key)
    )

  _addKey: (key) ->
    return if this._trackedKeys[key] is true

    if this.include is 'all'
      parts = key.split('.')
      for i in [parts.length...0] by -1
        key = parts.slice(0, i).join('.')
        break if this._trackedKeys[key] is true
        this._trackedKeys[key] = true
        this._add(key)
    else
      this._trackedKeys[key] = true
      this._add(key)

  _removeKey: (key) ->
    idx = this.list.indexOf(key)
    return unless idx >= 0

    delete this._trackedKeys[key]
    this._removeAt(idx)

    if this.include is 'all'
      # prune child branches.
      for k, idx in this.list when k.indexOf(key) is 0
        delete this._trackedKeys[k]
        this._removeAt(idx)

    null

  # (flat)mapPairs takes f: (k, v) -> x and returns List[x]
  mapPairs: (f) -> this.flatMap((key) => Varying.mapAll(f, new Varying(key), this.struct.watch(key)))
  flatMapPairs: (f) -> this.flatMap((key) => Varying.flatMapAll(f, new Varying(key), this.struct.watch(key)))

class IndexList extends DerivedList
  constructor: (@parent) ->
    super()

    this._lengthVaried = this.parent.watchLength().reactNow((length) =>
      ourLength = this.length
      if length > ourLength
        this._add(idx) for idx in [ourLength...length]
      else if length < ourLength
        this._removeAt(idx - 1) for idx in [ourLength...length] by -1
    )

  # (flat)mapPairs takes f: (k, v) -> x and returns List[x]
  mapPairs: (f) -> this.flatMap((idx) => Varying.mapAll(f, new Varying(idx), this.parent.watchAt(idx)))
  flatMapPairs: (f) -> this.flatMap((idx) => Varying.flatMapAll(f, new Varying(idx), this.parent.watchAt(idx)))

  destroy: ->
    this._lengthVaried.stop()
    super()

_dynamic = (f) -> (obj, options) ->
  Enumeration[if obj.isCollection is true then 'list' else if obj.isStruct is true then 'struct'][f](obj, options)
Enumeration =
  get: _dynamic('get')
  watch: _dynamic('watch')

  struct:
    get: (struct, options = {}) ->
      scope = options.scope ? 'all'
      include = options.include ? 'values'

      result = []
      traverser = if include is 'values' then traverse else if include is 'all' then traverseAll
      scanStruct = (struct) => traverser(struct.attributes, (key) => result.push(key.join('.')) unless result.indexOf(key) >= 0)
      if scope is 'all'
        ptr = struct
        while ptr?
          scanStruct(ptr)
          ptr = ptr._parent
      else if scope is 'direct'
        scanStruct(struct)
      result

    watch: (struct, options) -> new KeyList(struct, options)

  list:
    get: (list) -> (idx for idx in [0...list.length])
    watch: (list) -> new IndexList(list)


module.exports = { KeyList, IndexList, Enumeration }

