DerivedList = require('../list').DerivedList


# A read-only view into a proper `List` that only allows unique values from
# its parent. The values are ordered by first occurrence in the original list.
class UniqList extends DerivedList
  constructor: (@parent) ->
    super()

    # refers to the first occurence index of each element in the parent list.
    # TODO: ideally not using Map so that IE 10 and earlier work, and in the
    # splicey cases it's not blazingly efficient anyway. something cleverer?
    this.firsts = new Map()

    # because janus list splices values in blocks and then events changes, it's
    # not always easy to tell if we're appending to the end.
    this._vlen = 0

    this._tryAdd(elem, idx) for elem, idx in this.parent.list
    this.listenTo(this.parent, 'added', (elem, idx) => this._tryAdd(elem, idx))
    this.listenTo(this.parent, 'removed', (elem, idx) => this._tryRemove(elem, idx))
    this.listenTo(this.parent, 'moved', (elem, toIdx, fromIdx) => this._tryMove(elem, toIdx, fromIdx))

  # three cases: already had it (no change / move up) / it's new
  _tryAdd: (elem, parentNewIdx) ->
    isAppend = (parentNewIdx is this._vlen++)
    firsts = this.firsts

    # unless we are a pure append, we must shift around our indices.
    firsts.forEach((idx, k) -> firsts.set(k, idx + 1) if idx >= parentNewIdx) unless isAppend

    if (parentFirstIdx = firsts.get(elem))?
      # we already have this value; accept it if it's earlier.
      this._moveEarlier(elem, parentNewIdx) if parentNewIdx < parentFirstIdx
    else
      # this element is new; mark the index and figure out where to add it.
      firsts.set(elem, parentNewIdx)
      if isAppend then this._add(elem)
      else for x, idx in this.list when firsts.get(x) > parentNewIdx
        return this._add(elem, idx)
    return

  # three cases: removing later dupe / removed head (none remain / remnant found)
  _tryRemove: (elem, parentRmIdx) ->
    isUnappend = (parentRmIdx is --this._vlen)
    firsts = this.firsts

    # now we have to shift around all our pointer indices if we are removing.
    firsts.forEach((idx, k) -> firsts.set(k, idx - 1) if idx > parentRmIdx) unless isUnappend

    # now work out what to actually do to our list.
    if parentRmIdx > firsts.get(elem) then return # tail removal; ignore.
    else if this.parent.list.indexOf(elem) >= 0 then this._moveLater(elem) # sink to next.
    else # nothing left; remove and clear index.
      firsts.delete(elem)
      this._removeAt(this.list.indexOf(elem))
    return

  # three cases: moving around dupes / move earlier than head / move head backward
  _tryMove: (elem, parentToIdx, parentFromIdx) ->
    firsts = this.firsts
    parentFirstIdx = firsts.get(elem)

    # adjust indices. must adapt to movement direction.
    if parentFromIdx < parentToIdx
      firsts.forEach((idx, k) -> firsts.set(k, idx - 1) if parentFromIdx < idx <= parentToIdx)
    else
      firsts.forEach((idx, k) -> firsts.set(k, idx + 1) if parentToIdx <= idx < parentFromIdx)

    if parentFirstIdx < parentFromIdx and parentFirstIdx < parentToIdx then return
    else if parentToIdx < parentFirstIdx then this._moveEarlier(elem, parentToIdx)
    else this._moveLater(elem)
    return

  # takes an element that necessarily already exists in the list and moves it
  # to the appropriate spot in the uniq list relative to the given parent idx.
  _moveEarlier: (elem, parentIdx) ->
    this.firsts.set(elem, parentIdx)
    for x, idx in this.list when this.firsts.get(x) > parentIdx
      return this._moveAt(this.list.indexOf(elem), idx)
    return

  # given an element that already exists, locates where it ought to be in the
  # uniq list and places it there. _moveEarlier is more efficient if you know
  # the destination is earlier than the source; otherwise use this.
  _moveLater: (elem) ->
    parentIdx = this.parent.list.indexOf(elem)
    this.firsts.set(elem, parentIdx)
    for x, idx in this.list when this.firsts.get(x) > parentIdx
      return this._moveAt(this.list.indexOf(elem), idx - 1)
    this._moveAt(this.list.indexOf(elem), this.list.length - 1)
    return


module.exports = { UniqList }

