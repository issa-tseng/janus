{ List, DerivedList } = require('./list')
Varying = require('../core/varying').Varying
util = require('../util/util')

# A read-only view into a proper `List` that breaks the list's elements into
# separate lists, one for each unique identity returned by the partitioner
# function.
class PartitionedList extends DerivedList
  constructor: (@parent, @partitioner, @options = {}) ->
    super()

    # keep track of our internal lists so we can munge them by identity.
    this._partitions = {}

    this._add(elem) for elem in this.parent.list
    this.parent.on('added', (elem, idx) => this._add(elem, idx))
    this.parent.on('removed', (_, idx) => this._removeAt(idx))

  _add: (elem, idx) ->
    # NYI


util.extend(module.exports,
  PartitionedList: PartitionedList
)

