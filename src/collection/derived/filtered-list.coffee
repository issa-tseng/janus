{ List, DerivedList } = require('../list')
Varying = require('../../core/varying').Varying


# A read-only view into a proper `List` that filters out nonqualifying
# elements.
class FilteredList extends DerivedList
  constructor: (@parent, @filterer) ->
    super()

    this._filtereds = []
    this._idxMap = []

    this._add(elem, idx) for elem, idx in this.parent.list

    this.parent.on('added', (elem, idx) => this._add(elem, idx))
    this.parent.on('moved', (_, idx, oldIdx) => this._moveAt(oldIdx, idx))
    this.parent.on('removed', (elem, idx) => this._removeAt(idx))

  _add: (elem, idx) ->
    this._idxMap.splice(idx, 0, this._idxMap[idx - 1] ? -1)

    lastResult = false
    filtered = Varying.ly(this.filterer(elem)).react((result) =>
      result = result is true # force boolean because otherwise lastResult check fails.
      cidx = this._filtereds.indexOf(filtered)
      cidx = idx if cidx < 0 # this gets called once before we store away the Varied.

      if result isnt lastResult
        lastResult = (result is true)
        idxAdj = if result is true then 1 else -1

        # remove from list before updating mapping so we remove the correct element.
        if result is false
          List.prototype.removeAt.call(this, this._idxMap[cidx])

        # now update the mappings.
        this._idxMap[i] += idxAdj for i in [cidx...this._idxMap.length]

        # now insert the element in the correct destination slot.
        if result is true
          super(this.parent.at(cidx), this._idxMap[cidx])
    )

    # can't add this til after we have the Varied reference.
    this._filtereds.splice(idx, 0, filtered)

  _removeAt: (idx) ->
    # first adjust our reified list and index mapping.
    mappedIdx = this._idxMap[idx]
    delta = if idx is 0 then (mappedIdx + 1) else mappedIdx - this._idxMap[idx - 1]
    if delta is 1
      super(mappedIdx)
      for adjIdx in [idx..this._idxMap.length]
        this._idxMap[adjIdx] -= 1

    # then we can pull out the dead entries in our tracking lists.
    this._filtereds.splice(idx, 1)[0].stop()
    this._idxMap.splice(idx, 1)

    null

  _moveAt: (oldIdx, newIdx) ->
    # adjust filterers.
    [ filterer ] = this._filtereds.splice(oldIdx, 1)
    this._filtereds.splice(newIdx, 0, filterer)

    # adjust idxMap.
    oldMappedIdx = this._idxMap[oldIdx]
    delta = if oldIdx is 0 then (this._idxMap[oldIdx] + 1) else oldMappedIdx - this._idxMap[oldIdx - 1]
    if newIdx > oldIdx
      for i in [oldIdx..newIdx]
        this._idxMap[i] = this._idxMap[i + 1] - delta # can't run off end of list; noninclusive loop.
      this._idxMap[newIdx] = this._idxMap[newIdx - 1] + delta
    else if newIdx < oldIdx
      for i in [oldIdx..newIdx] by -1
        this._idxMap[i] = (this._idxMap[i - 1] ? -1) + delta
      this._idxMap[newIdx] = (this._idxMap[newIdx - 1] ? -1) + delta

    # adjust our reified list, but only if it was actually in the list at all.
    super(oldMappedIdx, this._idxMap[newIdx]) if delta is 1


module.exports = { FilteredList }

