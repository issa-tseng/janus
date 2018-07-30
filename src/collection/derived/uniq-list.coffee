DerivedList = require('../list').DerivedList


# A read-only view into a proper `List` that only allows unique values from
# its parent. By its nature, element ordering is undefined.
class UniqList extends DerivedList
  constructor: (@parent) ->
    super()

    this.counts = []

    this._tryAdd(elem) for elem in this.parent.list
    this.listenTo(this.parent, 'added', (elem) => this._tryAdd(elem))
    this.listenTo(this.parent, 'removed', (elem) => this._tryRemove(elem))

  _tryAdd: (elem) ->
    idx = this.list.indexOf(elem)

    if idx >= 0
      this.counts[idx] += 1
    else
      this.counts[this.counts.length] = 1
      this._add(elem)
    return

  _tryRemove: (elem) ->
    idx = this.list.indexOf(elem)

    if idx >= 0
      this.counts[idx] -= 1

      if this.counts[idx] is 0
        this.counts.splice(idx, 1)
        this._removeAt(idx)
    return


module.exports = { UniqList }

