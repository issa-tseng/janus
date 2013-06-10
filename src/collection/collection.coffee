# Reference require for all our collections.

util = require('../util/util')

util.extend(module.exports,
  OrderedIncrementalCollection: require('./types').OrderedIncrementalCollection

  List: require('./list').List
  IndefiniteList: require('./indefinite-list').IndefiniteList
  Set: require('./set').Set
  LazyList: require('./lazy-list').LazyList
  CachedLazyList: require('./lazy-list').CachedLazyList
)

