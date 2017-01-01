DerivedList = require('../list').DerivedList
util = require('../../util/util')


class CattedList extends DerivedList
  constructor: (@lists) ->
    super()

    this.list = util.foldLeft([])(this.lists, (elems, list) -> elems.concat(list.list))

    for list, listIdx in this.lists
      do (list, listIdx) =>
        # gets the index of the given element in our concatted list.
        getOverallIdx = (itemIdx) => util.foldLeft(0)(this.lists[0...listIdx], (length, list) -> length + list.list.length) + itemIdx

        list.on('added', (elem, idx) => this._add(elem, getOverallIdx(idx)))
        list.on('removed', (_, idx) => this._removeAt(getOverallIdx(idx)))
        list.on('moved', (_, idx, oldIdx) => this._moveAt(getOverallIdx(oldIdx), getOverallIdx(idx)))


module.exports = { CattedList }

