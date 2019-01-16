# **Sets** are possibly-ordered sets of objects. The base `Set` implementation
# is pretty simple; it just bails if we already have an object upon adding.
# Otherwise all behaviour is delegated to our parent.
#
# No guaranteed ordering semantic is provided. As such, #move and #moveAt are
# unavailable.

{ Varying } = require('../core/varying')
{ Mappable } = require('./collection')
{ List } = require('./list')
util = require('../util/util')

class Set extends Mappable
  constructor: (init) ->
    super()

    this._watched = []
    this._watchers = []
    this._list = new List()
    this.list = this._list.list

    this.add(init) if init?

  add: (elems) ->
    # Normalize the argument to an array, then add each elem if possible.
    elems = [ elems ] unless util.isArray(elems)
    for elem in elems when not this.includes(elem)
      widx = this._watched.indexOf(elem)
      this._watchers[widx].set(true) if widx >= 0
      this._list.add(elem)
      this.emit('added', elem)
    elems

  remove: (elem) ->
    widx = this._watched.indexOf(elem)
    this._watchers[widx].set(false) if widx >= 0

    idx = this.list.indexOf(elem)
    return undefined unless idx >= 0
    this._list.removeAt(idx)
    this.emit('removed', elem)
    elem

  includes: (elem) -> this.list.indexOf(elem) >= 0
  watchIncludes: (elem) -> 
    v = new Varying(this.includes(elem))
    this._watched.push(elem)
    this._watchers.push(v)
    v

  Object.defineProperty(@prototype, 'length', get: -> this.list.length)
  watchLength: -> this._list.watchLength()

  flatten: -> this._flatten$ ?= new (require('./derived/flattened-set').FlattenedSet)(this)

  # a Set is already its own enumeration; it is unordered, unindexed, and the
  # only addressing method is the things in it.
  enumerate: -> this.list.slice()
  enumeration: -> this

  # all the list-like functions can get implemented based on our captive list. this
  # does mean that the resulting derivedlists will impose an ordering and indices
  # but i feel like we can live with that. maybe someday we do this custom. (defining
  # Set#map as returning OrderedMappable solves some philosophical issues anyway.)
  filter: (f) -> this._list.filter(f)
  map: (f) -> this._list.map(f)
  flatMap: (f) -> this._list.flatMap(f)
  uniq: -> this # lol
  any: (f) -> this._list.any(f)

  # we don't bother with the folds yet because they're not officially supported yet.

  @deserialize: List.deserialize # eventually calls new this(items) so we are fine.
  @of: List.of


module.exports = { Set }

