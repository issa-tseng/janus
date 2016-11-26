# Reference require for all our collections.

util = require('../util/util')

util.extend(module.exports,
  Collection: require('./types').Collection
  OrderedCollection: require('./types').OrderedCollection

  List: require('./list').List
  DerivedList: require('./list').DerivedList
  MappedList: require('./mapped-list').MappedList
  FlatMappedList: require('./mapped-list').FlatMappedList
  FilteredList: require('./filtered-list').FilteredList
  CattedList: require('./catted-list').CattedList
  PartitionedList: require('./partitioned-list').PartitionedList
  UniqList: require('./uniq-list').UniqList
  TakenList: require('./uniq-list').TakenList

  Set: require('./set').Set
)

