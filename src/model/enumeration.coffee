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
    this.listenTo(struct, 'anyChanged', (key, newValue, oldValue) =>
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
    delete this._trackedKeys[key]
    this._removeAt(this.list.indexOf(key))

    if this.include is 'all'
      # prune child branches.
      for k, idx in this.list when k.indexOf(key) is 0
        delete this._trackedKeys[k]
        this._removeAt(idx)

    null

  # (flat)mapPairs takes f: (x, y) -> z and returns List[z]
  mapPairs: (f) -> this.flatMap((key) => Varying.mapAll(f, new Varying(key), this.struct.watch(key)))
  flatMapPairs: (f) -> this.flatMap((key) => Varying.flatMapAll(f, new Varying(key), this.struct.watch(key)))


Enumeration = {
  get: (struct, options = {}) ->
    scope = options.scope ? 'all'
    include = options.include ? 'values'

    result = []
    traverser = if include is 'values' then traverse else if include is 'all' then traverseAll
    scanStruct = (struct) => traverser(struct.attributes, (key) => result.push(key) unless result.indexOf(key) >= 0)
    if scope is 'all'
      ptr = struct
      while ptr?
        scanStruct(ptr)
        ptr = ptr._parent
    else if scope is 'direct'
      scanStruct(struct)
    result

  watch: (struct, options) -> new KeyList(struct, options)
}


module.exports = { KeyList, Enumeration }

