# Some general types that the specific implementations can derive off of,
# mostly to express behavioral characteristics that a `View` can count on
# so that we can easily register against these collections.

Model = require('../model/model').Model
util = require('../util/util')

# An `OrderedIncrementalList` provides `add` and `remove` events for every
# element that is added or removed from the list, along with a positional
# argument.
class OrderedIncrementalList extends Model

util.extend(module.exports,
  OrderedIncrementalList: OrderedIncrementalList
)

