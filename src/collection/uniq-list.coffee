PartitionedList = require('./partitioned-list').PartitionedList
util = require('../util/util')

# A read-only view into a proper `List` that filters out nonqualifying
# elements. Doesn't yet respect positional stability from parent.
class UniqList extends PartitionedList
  constructor: (@lists, @options = {}) ->
    elems = util.foldLeft([])(this.lists, (elems, list) -> elems.concat(list.list))
    super(elems)

    # NYI -- depends on PartitionedList


util.extend(module.exports,
  UniqList: UniqList
)

