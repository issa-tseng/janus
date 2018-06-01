# An Enumeration can be attached to or run against a Map. It allows live- or
# static- traversal of that Map, respectively.
#
# Enumerations are separate from Maps and not a derivation or inherent feature
# so that they are only instantiated and incur overhead cost when actually needed,
# and because enumeration behaviour options like shadow-flattening and deep traversal
# can be chosen at will.

{ Varying } = require('../core/varying')
{ DerivedList } = require('../collection/list')
{ Map } = require('./map')
{ traverse, traverseAll, deepGet } = require('../util/util')

class KeyList extends DerivedList
  constructor: (@map, options = {}) ->
    super()
    this.scope = options.scope ? 'all'
    this.include = options.include ? 'values'

    # it's faster to check an object than call indexOf all the time.
    this._trackedKeys = {}

    # add initial keys.
    scanMap = (map) => traverse(map.data, (key) => this._addKey(key.join('.')))
    if this.scope is 'all'
      ptr = this.map
      while ptr?
        scanMap(ptr)
        ptr = ptr._parent
    else if this.scope is 'direct'
      scanMap(this.map)

    # listen for future keys.
    this.listenTo(this.map, 'anyChanged', (key, newValue, oldValue) =>
      if this.scope is 'direct'
        # TODO: is there a cleverer way to do this?
        ownValue = deepGet(this.map.data, key)
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
  mapPairs: (f) -> this.flatMap((key) => Varying.mapAll(f, new Varying(key), this.map.watch(key)))
  flatMapPairs: (f) -> this.flatMap((key) => Varying.flatMapAll(f, new Varying(key), this.map.watch(key)))

class IndexList extends DerivedList
  constructor: (@parent) ->
    super()

    this._lengthVaried = this.parent.watchLength().react((length) =>
      ourLength = this.length
      if length > ourLength
        this._add(idx) for idx in [ourLength...length]
      else if length < ourLength
        this._removeAt(idx - 1) for idx in [ourLength...length] by -1
    )

  # (flat)mapPairs takes f: (k, v) -> x and returns List[x]
  mapPairs: (f) -> this.flatMap((idx) => Varying.mapAll(f, new Varying(idx), this.parent.watchAt(idx)))
  flatMapPairs: (f) -> this.flatMap((idx) => Varying.flatMapAll(f, new Varying(idx), this.parent.watchAt(idx)))

  _destroy: -> this._lengthVaried.stop()

_dynamic = (f) -> (obj, options) ->
  Enumeration[if obj.isCollection is true then 'list' else if obj.isMap is true then 'map'][f](obj, options)
Enumeration =
  get: _dynamic('get')
  watch: _dynamic('watch')

  map:
    get: (map, options = {}) ->
      scope = options.scope ? 'all'
      include = options.include ? 'values'

      result = []
      traverser = if include is 'values' then traverse else if include is 'all' then traverseAll
      scanMap = (map) => traverser(map.data, (key) => result.push(key.join('.')) unless result.indexOf(key) >= 0)
      if scope is 'all'
        ptr = map
        while ptr?
          scanMap(ptr)
          ptr = ptr._parent
      else if scope is 'direct'
        scanMap(map)
      result

    watch: (map, options) -> new KeyList(map, options)

  list:
    get: (list) -> (idx for idx in [0...list.length])
    watch: (list) -> new IndexList(list)


module.exports = { KeyList, IndexList, Enumeration }

