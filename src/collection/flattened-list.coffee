List = require('./list').List
DerivedList = require('./list').DerivedList
util = require('../util/util')

class FlattenedList extends DerivedList
  constructor: (@source, @options = {}) ->
    super()

    this._listListeners = new List()

    this.source.on('removed', (list, idx) => this._removeList(list, idx))
    this.source.on('added', (list, idx) => this._addList(list, idx))

    this._addList(list, idx) for list, idx in this.source.list

  _getOverallIdx: (list, offset = 0) ->
    listIdx = this.source.list.indexOf(list)
    util.foldLeft(0)(this.source.list[0...listIdx], (length, list) -> length + list.list.length) + offset

  _addList: (list, idx) ->
    listeners = {
      added: (elem, idx) => this._add(elem, this._getOverallIdx(list, idx))
      removed: (_, idx) => this._removeAt(this._getOverallIdx(list, idx))
    }
    list.on(event, handler) for event, handler of listeners
    this._listListeners.add(listeners, idx)

    this._add(elem, this._getOverallIdx(list, idx)) for elem, idx in list.list

  _removeList: (list, idx) ->
    listStartIdx = this._getOverallIdx(list)
    this._removeAt(listStartIdx) for _ in list.list

    list.off(event, handler) for event, handler of this._listListeners.removeAt(idx)

util.extend(module.exports,
  FlattenedList: FlattenedList
)

