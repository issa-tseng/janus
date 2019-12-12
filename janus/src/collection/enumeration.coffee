# An Enumeration can be attached to or run against a Map. It allows live- or
# static- traversal of that Map, respectively.
#
# Enumerations are separate from Maps and not a derivation or inherent feature
# so that they are only instantiated and incur overhead cost when actually needed,
# and because enumeration behaviour options like shadow-flattening and deep traversal
# can be chosen at will.

{ Varying } = require('../core/varying')
{ DerivedList } = require('../collection/list')
{ Set } = require('../collection/set')
{ Map } = require('./map')
{ traverse, deepGet } = require('../util/util')

class KeySet extends Set
  constructor: (@parent) ->
    super()
    this._list.add(Enumeration.map_(this.parent))
    this.listenTo(this.parent, 'changed', (key, newValue, oldValue) =>
      if newValue? and not oldValue? then Set.prototype.add.call(this, key)
      else if oldValue? and not newValue? then Set.prototype.remove.call(this, key)
      return
    )

  mapPairs: (f) -> this.flatMap((k) => Varying.mapAll(f, new Varying(k), this.parent.get(k)))
  flatMapPairs: (f) -> this.flatMap((k) => Varying.flatMapAll(f, new Varying(k), this.parent.get(k)))
  add: undefined
  remove: undefined

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
    updater = update(this.parent, this)
    this.listenTo(this.parent, 'added', updater)
    this.listenTo(this.parent, 'removed', updater)
    updater()

  # (flat)mapPairs takes f: (k, v) -> x and returns List[x]
  mapPairs: (f) -> this.flatMap((idx) => Varying.mapAll(f, new Varying(idx), this.parent.at(idx)))
  flatMapPairs: (f) -> this.flatMap((idx) => Varying.flatMapAll(f, new Varying(idx), this.parent.at(idx)))


_dynamic = (suffix) -> (obj, options) ->
  type = if obj.isMappable is true then 'list' else if obj.isMap is true then 'map'
  Enumeration[type + suffix](obj, options)
Enumeration =
  get_: _dynamic('_')
  get: _dynamic('')

  map_: (map) ->
    result = []
    scanMap = (map) => traverse(map.data, (key) =>
      joined = key.join('.')
      result.push(joined) unless result.indexOf(joined) >= 0
    )
    ptr = map
    while ptr?
      scanMap(ptr)
      ptr = ptr._parent
    result

  map: (map, options) -> new KeySet(map, options)

  list_: (list) -> (idx for idx in [0...list.length_])
  list: (list) -> new IndexList(list)


module.exports = { KeySet, IndexList, Enumeration }

