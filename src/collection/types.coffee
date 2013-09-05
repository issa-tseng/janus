# Some general types that the specific implementations can derive off of,
# mostly to express behavioral characteristics that a `View` can count on
# so that we can easily register against these collections.

Model = require('../model/model').Model
util = require('../util/util')

# A `Collection` provides `add` and `remove` events for every element that is
# added or removed from the list.
class Collection extends Model
  # Create a new FilteredList based on this list, with the member check
  # function `f`.
  #
  # **Returns** a `FilteredList`
  filter: (f) -> new (require('./filtered-list').FilteredList)(this, f)

  # Create a new mapped List based on this list, with the mapping function `f`.
  #
  # **Returns** a `MappedList`
  map: (f) -> new (require('./mapped-list').MappedList)(this, f)

  # Create a new concatenated List based on this List, along with the other
  # Lists provided in the call. Can be passed in either as an arg list of Lists
  # or as an array of Lists.
  #
  # **Returns** a `CattedList`
  concat: (lists...) ->
    lists = lists[0] if util.isArray(lists[0]) and lists.length is 1
    new (require('./catted-list').CattedList)([ this ].concat(lists))

  # Create a new PartitionedList based on this List, with the identification
  # function `f`. If no function is provided, the element is used directly.
  #
  # **Returns** a `PartitionedList`
  partition: (f) -> new (require('./partitioned-list').PartitionedList)(this, f)

  # Create a new UniqList based on this List, with the identification function
  # `f`. If no function is provided, the element is used directly.
  #
  # **Returns** a `UniqList`
  uniq: (f) -> new (require('./uniq-list').UniqList)(this, f)

  # Perform some action once for each member of this List, upon insertion.
  # Throw away the result.
  react: (f) -> this.on('added', f)

  # Same as #react() but immediately also runs against all elements in the
  # list.
  reactNow: (f) ->
    f(elem) for elem in this.list
    this.on('added', f)


# An `OrderedCollection` provides `add` and `remove` events for every element
# that is added or removed from the list, along with a positional argument.
class OrderedCollection extends Collection


util.extend(module.exports,
  Collection: Collection
  OrderedCollection: OrderedCollection
)

