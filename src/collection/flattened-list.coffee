{ List, DerivedList } = require('./list')
util = require('../util/util')


class FlattenedList extends DerivedList
  constructor: (@parent, @options = {}) ->
    super()

    this._listListeners = new List()

    this._addObj(list, idx) for list, idx in this.parent.list
    this.parent.on('added', (obj, idx) => this._addObj(obj, idx))
    this.parent.on('moved', (_, idx, oldIdx) => 0)#??
    this.parent.on('removed', (obj, idx) => this._removeObj(obj, idx))

  _getOverallIdx: (parentIdx, offset = 0) ->
    util.foldLeft(0)(this.parent.list[0...parentIdx], (length, x) -> length + (if x?.isCollection is true then x.length else 1)) + offset

  _addObj: (obj, idx) ->
    if obj?.isCollection is true
      listeners = {
        added: (elem, offset) =>
          this._add(elem, this._getOverallIdx(this._listListeners.list.indexOf(listeners), offset))
        removed: (_, offset) =>
          this._removeAt(this._getOverallIdx(this._listListeners.list.indexOf(listeners), offset))
      }
      obj.on(event, handler) for event, handler of listeners
      this._listListeners.add(listeners, idx)

      this._add(elem, this._getOverallIdx(idx, offset)) for elem, offset in obj.list
    else
      this._add(obj, this._getOverallIdx(idx))

  _removeObj: (obj, idx) ->
    objStartIdx = this._getOverallIdx(idx)
    listeners = this._listListeners.removeAt(idx)

    if obj?.isCollection is true
      obj.off(event, handler) for event, handler of listeners
      this._removeAt(objStartIdx) for _ in obj.list
    else
      this._removeAt(objStartIdx)

    null

  destroy: ->
    this.parent.list[idx].off(event, handler) for event, handler of listeners for listeners in this._listListeners.list when listeners?
    super()


module.exports = { FlattenedList }

