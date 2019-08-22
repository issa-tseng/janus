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
  constructor: (@target, options = {}) ->
    super()
    this.scope = options.scope ? 'all'
    this.include = options.include ? 'values'

    # it's faster to check an object than call indexOf all the time.
    this._trackedKeys = {}

    # add initial keys.
    scanMap = (map) => traverse(map.data, (key) => this._addKey(key.join('.')))
    if this.scope is 'all'
      ptr = this.target
      while ptr?
        scanMap(ptr)
        ptr = ptr._parent
    else if this.scope is 'direct'
      scanMap(this.target)

    # listen for future keys.
    this.listenTo(this.target, 'changed', (key, newValue, oldValue) =>
      if this.scope is 'direct'
        # TODO: is there a cleverer way to do this?
        ownValue = deepGet(this.target.data, key)
        return if ownValue isnt newValue

      if newValue? and not oldValue?
        this._addKey(key)
      else if oldValue? and not newValue?
        this._removeKey(key)
      return
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
    return

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
    return

  # (flat)mapPairs takes f: (k, v) -> x and returns List[x]
  mapPairs: (f) -> this.flatMap((key) => Varying.mapAll(f, new Varying(key), this.target.get(key)))
  flatMapPairs: (f) -> this.flatMap((key) => Varying.flatMapAll(f, new Varying(key), this.target.get(key)))

class IndexList extends DerivedList
  update = (parent, self) -> ->
    length = parent.length_
    ourLength = self.length_
    if length > ourLength
      self._add(idx) for idx in [ourLength...length]
    else if length < ourLength
      self._removeAt(idx - 1) for idx in [ourLength...length] by -1
    return

  constructor: (@parent) ->
    super()
    this._update = update(this.parent, this)
    this.parent._on('added', this._update)
    this.parent._on('removed', this._update)
    this._update()

  # (flat)mapPairs takes f: (k, v) -> x and returns List[x]
  mapPairs: (f) -> this.flatMap((idx) => Varying.mapAll(f, new Varying(idx), this.parent.at(idx)))
  flatMapPairs: (f) -> this.flatMap((idx) => Varying.flatMapAll(f, new Varying(idx), this.parent.at(idx)))

  __destroy: ->
    this.parent.off('added', this._update)
    this.parent.off('removed', this._update)
    return


_dynamic = (suffix) -> (obj, options) ->
  type = if obj.isMappable is true then 'list' else if obj.isMap is true then 'map'
  Enumeration[type + suffix](obj, options)
Enumeration =
  get_: _dynamic('_')
  get: _dynamic('')

  map_: (map, options = {}) ->
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

  map: (map, options) -> new KeyList(map, options)

  list_: (list) -> (idx for idx in [0...list.length_])
  list: (list) -> new IndexList(list)


module.exports = { KeyList, IndexList, Enumeration }

