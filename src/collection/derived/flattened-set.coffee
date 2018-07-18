{ Set } = require('../set')

# we basically want to do a List.flatten().uniq(), which would be daunting except
# that we don't care /at all/ about ordering so we can play super fast and loose.
class FlattenedSet extends Set
  constructor: (@parent) ->
    super()
    this._counts = [] # tracks how many of each thing we have.

    this.listenTo(this.parent, 'added', (elem) => this._tryAdd(elem))
    this.listenTo(this.parent, 'removed', (elem) => this._tryRemove(elem))
    this._tryAdd(elem) for elem in this.parent.list

  _tryAdd: (elem) ->
    if elem?.isMappable is true and elem isnt this.parent and elem isnt this
      # don't add the element, add its elements and watch for more.
      this.listenTo(elem, 'added', (elem) => this._tryAddOne(elem))
      this.listenTo(elem, 'removed', (elem) => this._tryRemove(elem))
      this._tryAddOne(subelem) for subelem in elem.list
    else
      this._tryAddOne(elem)
    return

  # never treats anything as a mappable:
  _tryAddOne: (elem) ->
    idx = this.list.indexOf(elem)

    if idx >= 0
      this._counts[idx] += 1
    else
      this._counts[this.list.length] = 1
      Set.prototype.add.call(this, elem)
    return

  _tryRemove: (elem) ->
    idx = this.list.indexOf(elem)

    if idx >= 0
      this._counts[idx] -= 1
      if this._counts[idx] is 0
        this._counts.splice(idx, 1)
        Set.prototype.remove.call(this, elem)
    else
      # if we don't know what this is we must have found a flattened child.
      this._tryRemove(subelem) for subelem in elem.list
      this.unlistenTo(elem)
    return

  add: undefined
  remove: undefined
  putAll: undefined

module.exports = { FlattenedSet }

