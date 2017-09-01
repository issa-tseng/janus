{ List, DerivedList } = require('../list')
util = require('../../util/util')


class FlattenedList extends DerivedList
  constructor: (@parent, @options = {}) ->
    super()

    this._listListeners = new List()

    this._addObj(list, idx) for list, idx in this.parent.list
    this.parent.on('added', (obj, idx) => this._addObj(obj, idx))
    this.parent.on('moved', (obj, idx, oldIdx) => this._moveObj(obj, oldIdx, idx))
    this.parent.on('removed', (obj, idx) => this._removeObj(obj, idx))

  sizeof = (x) -> if x?.isCollection is true then x.length else 1
  _getOverallIdx: (parentIdx, offset = 0) ->
    util.foldLeft(0)(this.parent.list[0...parentIdx], (length, x) -> length + sizeof(x)) + offset

  _addObj: (obj, idx) ->
    if obj?.isCollection is true
      listeners = {
        added: (elem, offset) =>
          this._add(elem, this._getOverallIdx(this._listListeners.list.indexOf(listeners), offset))
        moved: (elem, newIdx, oldIdx) =>
          mappedBase = this._getOverallIdx(this._listListeners.list.indexOf(listeners))
          this._moveAt(mappedBase + oldIdx, mappedBase + newIdx)
        removed: (_, offset) =>
          this._removeAt(this._getOverallIdx(this._listListeners.list.indexOf(listeners), offset))
      }
      obj.on(event, handler) for event, handler of listeners
      this._listListeners.add(listeners, idx)

      this._add(elem, this._getOverallIdx(idx, offset)) for elem, offset in obj.list
    else
      this._add(obj, this._getOverallIdx(idx))

  _moveObj: (obj, oldIdx, newIdx) ->
    # this is moving toplevel items; items within sublists are handled via the
    # listeners set up in #_addObj.
    mOldIdx = this._getOverallIdx(oldIdx)
    mNewIdx = this._getOverallIdx(newIdx)

    if obj?.isCollection is true
      # our parent list has already changed, so the mapped indices need another
      # adjustment in order to reflect the pre-move indices in our own list:
      if newIdx > oldIdx
        mNewIdx += sizeof(obj) # adj up by what used to be at oldIdx.
        mNewIdx -= sizeof(this.parent.list[newIdx - 1]) # adj down by what shifted into our target.
      if newIdx < oldIdx
        mOldIdx -= sizeof(obj) # adj down by what was shoved in.
        mOldIdx += sizeof(this.parent.list[oldIdx]) # adj up by what was shifted out from under us.

      if newIdx > oldIdx # moving down the list.
        this._moveAt(mOldIdx, mNewIdx) for _ in [0...obj.length]
      else if newIdx < oldIdx # moving up.
        this._moveAt(mOldIdx + offset, mNewIdx + offset) for offset in [0...obj.length]
    else
      this._moveAt(mOldIdx, mNewIdx)

    # no matter what, adjust our list listeners.
    this._listListeners.moveAt(oldIdx, newIdx)

  _removeObj: (obj, idx) ->
    objStartIdx = this._getOverallIdx(idx)
    listeners = this._listListeners.removeAt(idx)

    if obj?.isCollection is true
      obj.off(event, handler) for event, handler of listeners
      this._removeAt(objStartIdx) for _ in obj.list
    else
      this._removeAt(objStartIdx)

    null

  _destroy: ->
    this.parent.list[idx].off(event, handler) for event, handler of listeners for listeners, idx in this._listListeners.list when listeners?


module.exports = { FlattenedList }

