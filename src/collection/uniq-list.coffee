DerivedList = require('./list').DerivedList
util = require('../util/util')

# A read-only view into a proper `List` that only allows unique values from
# its parent.
class UniqList extends DerivedList
  constructor: (@parent, @options = {}) ->
    super()

    this.counts = []

    this._tryAdd(elem) for elem in parent.list
    parent.on('added', (elem) => this._tryAdd(elem))
    parent.on('removed', (elem) => this._tryRemove(elem))

  _tryAdd: (elem) ->
    idx = this.list.indexOf(if this.options.by then this.options.by(elem) else elem)

    if idx >= 0
      this.counts[idx] += 1
    else
      this.counts[this.counts.length] = 1
      this._add(elem)

  _tryRemove: (elem) ->
    idx = this.list.indexOf(if this.options.by then this.options.by(elem) else elem)

    if idx >= 0
      this.counts[idx] -= 1

      if this.counts[idx] is 0
        this.counts.splice(idx, 1)
        this._removeAt(idx)

util.extend(module.exports,
  UniqList: UniqList
)

