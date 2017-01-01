# **Sets** are possibly-ordered sets of objects. The base `Set` implementation
# is pretty simple; it just bails if we already have an object upon adding.
# Otherwise all behaviour is delegated to our parent.
#
# No guaranteed ordering semantic is provided. As such, #move and #moveAt are
# unavailable.

{ Varying } = require('../core/varying')
{ List } = require('./list')
util = require('../util/util')

# TODO: by derivation this inheritance implies Set: OrderedCollection which is
# obviously wrong. But we don't currenty really rely on that identity yet, so
# we can punt the question.
class Set extends List
  _initialize: ->
    # TODO: someday WeakMaps will be better.
    this._watched = []
    this._watchers = []

  add: (elems) ->
    # Normalize the argument to an array, then add each elem if possible.
    elems = [ elems ] unless util.isArray(elems)
    for elem in elems when not this.has(elem)
      widx = this._watched.indexOf(elem)
      this._watchers[widx].set(true) if widx >= 0
      List.prototype.add.call(this, elem) # using super here breaks the cs compiler (??)
    elems

  remove: (elem) ->
    widx = this._watched.indexOf(elem)
    this._watchers[widx].set(false) if widx >= 0

    idx = this.list.indexOf(elem)
    return undefined unless idx >= 0
    List.prototype.removeAt.call(this, idx)

  putAll: (elems) ->
    list = this.list.slice(0)
    elems = [ elems ] unless util.isArray(elems)
    this.remove(x) for x in list when elems.indexOf(x) < 0
    this.add(elems)

  has: (elem) -> this.list.indexOf(elem) >= 0
  watchHas: (elem) -> 
    v = new Varying(this.has(elem))
    this._watched.push(elem)
    this._watchers.push(v)
    v

  at: undefined
  watchAt: undefined
  removeAt: undefined
  move: undefined
  moveAt: undefined
  put: undefined


module.exports = { Set }

