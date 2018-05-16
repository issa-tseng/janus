# Some general types that the specific implementations can derive off of,
# mostly to express behavioral characteristics that a `View` can count on
# so that we can easily register against these collections.

{ Base } = require('../core/base')
{ Varying } = require('../core/varying')
{ Traversal } = require('./traversal')
folds = require('./folds')
{ IndexOfFold } = require('./derived/indexof-fold')


# cache this circularly referenced module once we fetch it:
Enumeration$ = null

# The base for all data structures. Provides basic enumeration functions around
# keys/indices, and all classes implementing Enumerable are expected to also
# provide:
# * get: (key) -> value
# * set: (key, value) -> void
# * watch: (key) -> Varying[value]
# * shadow: -> Enumerable
# * mapPairs: ((key, value) -> T) -> [T]
# * flatMapPairs: ((key, value) -> Varying?[T]) -> [T]
class Enumerable extends Base
  isEnumerable: true

  # Calls into the Enumeration module to get either a live KeySet or a static
  # array enumerating the keys of this Map or List. The options are passed
  # directly to Enumeration and only matter for Maps, but consist of:
  # * scope: (all|direct) all inherited or only dir
  enumerate: (options) -> (Enumeration$ ?= require('./enumeration').Enumeration).get(this, options)
  enumeration: (options) ->
    Enumeration$ ?= require('./enumeration').Enumeration
    if options?
      Enumeration$.watch(this, options)
    else
      (this.enumeration$ ?= Base.managed(=> Enumeration$.watch(this)))()

  serialize: -> Traversal.getNatural(this, Traversal.default.serialize)

  watchModified: -> if this._parent? then this.watchDiff(this._parent) else new Varying(false)
  watchDiff: (other) -> Traversal.asList(this, Traversal.default.diff, { other })

# A `Collection` provides `add` and `remove` events for every element that is
# added or removed from the list.
class Collection extends Enumerable
  isCollection: true

  # Create a new FilteredList based on this list, with the member check
  # function `f`.
  #
  # **Returns** a `FilteredList`
  filter: (f) -> new (require('./derived/filtered-list').FilteredList)(this, f)

  # Create a new mapped List based on this list, with the mapping function `f`.
  #
  # **Returns** a `MappedList`
  map: (f) -> new (require('./derived/mapped-list').MappedList)(this, f)

  # Create a new mapped List based on this list, with the mapping function `f`.
  # Due to the flatMap, `f` may return a `Varying` that changes, which will in
  # turn change the value in the resulting list.
  #
  # **Returns** a `MappedList`
  flatMap: (f) -> new (require('./derived/mapped-list').FlatMappedList)(this, f)

  # Rely on enumeration to give us mapPairs and flatMapPairs:
  mapPairs: (f) -> this.enumeration().mapPairs(f)
  flatMapPairs: (f) -> this.enumeration().flatMapPairs(f)

  # Create a new FlattenedList based on this List.
  #
  # **Returns** a `FlattenedList`
  flatten: -> new (require('./derived/flattened-list').FlattenedList)(this)

  # Create a new UniqList based on this List.
  #
  # **Returns** a `UniqList`
  uniq: -> new (require('./derived/uniq-list').UniqList)(this)

  # See if any element in this list qualifies for the condition.
  any: (f) -> folds.any(new (require('./derived/mapped-list').FlatMappedList)(this, f))

  # fold left across the list.
  fold: (memo, f) -> folds.fold(this, memo, f)

  # scan left across the list. (alt implementation)
  scanl: (memo, f) -> folds.scanl(this, memo, f)

  # fold left across the list. (alt implementation)
  foldl: (memo, f) -> folds.foldl(this, memo, f)

  # get the minimum number on the list.
  min: -> folds.min(this)

  # get the maximum number on the list.
  max: -> folds.max(this)

  # get the sum of this list.
  sum: -> folds.sum(this)

  # return the index of an item in the list. value may be Varying[x].
  indexOf: (value) -> IndexOfFold.indexOf(this, value)


# An `OrderedCollection` provides `add` and `remove` events for every element
# that is added or removed from the list, along with a positional argument.
class OrderedCollection extends Collection
  isOrderedCollection: true

  # Create a list that always takes the first x elements of this collection,
  # where x may be a number or a Varying[Int].
  #
  # **Returns** a `TakenList`
  take: (x) -> new (require('./derived/taken-list').TakenList)(this, x)

  # Create a new concatenated List based on this List, along with the other
  # Lists provided in the call. Can be passed in either as an arg list of Lists
  # or as an array of Lists.
  #
  # **Returns** a `CattedList`
  concat: (lists...) ->
    new (require('./derived/catted-list').CattedList)([ this ].concat(lists))

  # get the strings of this list joined by some string.
  join: (joiner) -> folds.join(this, joiner)


module.exports = { Enumerable, Collection, OrderedCollection }

