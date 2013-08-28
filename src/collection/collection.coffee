# Reference require for all our collections.

util = require('../util/util')

util.extend(module.exports,
  Collection: require('./types').Collection
  OrderedCollection: require('./types').OrderedCollection

  List: require('./list').List
  DerivedList: require('./list').DerivedList
  MappedList: require('./mapped-list').MappedList
  FilteredList: require('./filtered-list').FilteredList
  CattedList: require('./catted-list').CattedList
  PartitionedList: require('./partitioned-list').PartitionedList
  UniqList: require('./uniq-list').UniqList

  Set: require('./set').Set

  IndefiniteList: require('./indefinite-list').IndefiniteList

  LazyList: require('./lazy-list').LazyList
  CachedLazyList: require('./lazy-list').CachedLazyList
  Window: require('./window').Window
)

