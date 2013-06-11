# List whose contents are unspecified until requested.
# Indexes, Index ranges, and the length of the list may all be requested,
# which will result in a Varying. The Varying will populate with the result
# when available, as well as change if the list itself changes.

util = require('../util/util')
{ Coverage, Range } = require('../util/range')
List = require('./list').List
Model = require('../model/model').Model
Varying = require('../core/varying')


# Helper to wrap a Range with another, and destroy the inner when the outer is
# destroyed.
wrapAndSealFate = (range, f) ->
  wrapped = new Range(range.lower, range.upper, range)
  wrapped.on('destroying', -> range.destroy())
  wrapped

# Helper to update the relevant segment of a target range from a source range.
rangeUpdater = (from, to) -> ->
  if from.value instanceof List
    to.value.put(
      Math.max(from.lower - to.lower, 0),
      from.value[Math.max(to.lower - from.lower, 0)..(from.upper - to.lower)]
    )


# A LazyList does not itself necessarily resemble a list; its contents are
# unresolved until the list is required to return a range, at which point
# the list itself does not record any item membership, but instead returns
# slices (a `Varying` whose lifecycle can be managed) of the relevant range
# of items. Thus, we derive from Model instead of any Collection parent class.
class LazyList extends Model

  @bind('signature').fromVarying(-> this._signature())

  # We need to init some structures to track our cache by cachekey and idx.
  constructor: ->
    super()

    this._activeRanges = new List()
    this._watchSignature()

  # We need to refresh our results if our signature changes.
  _watchSignature: ->
    this.watch('signature').on 'changed', (key) =>
      for range in this._activeRanges.list
        # this is a bit of a knuckleheaded approach that will over time leak
        # stack levels. come up with something better, you knucklehead.
        range.setValue(this._range(range._idx, range._length))

  # We can rely on `#range` and just transform its contained result here.
  #
  # **Returns**: A `Varying` whose contents should be the result at the index.
  at: (idx) ->
    this.range(idx, idx).map (result) ->
      if result instanceof List
        result[0]
      else
        result

  # Because of how we want to override `range`'s behavior down the line, we
  # call `#_range()` to do the work of actually resolving the range.
  #
  # **Returns**: A `Varying` whose contents should be the result of evaluating
  # the range.
  range: (lower, upper) ->
    # Grab and store our `Varying`. wrap the one we get back so that we can
    # forcibly discard what our upstream is trying to do to it later.
    range = wrapAndSealFate(this._range(lower, upper))
    this._activeRanges.add(range)
    range

  # Here we override to do the heavy lifting of actually grabbing a range of
  # this `LazyList`.
  #
  # **Returns**: A `Varying` whose contents should be the result of evaluating
  # the range.
  _range: (lower, upper) ->

  # Length is necessary for some practical considerations rendering a lazy
  # list; for instance, one probably wants to render a pager which knows how
  # many pages it should have.
  #
  # **Returns**: A `Varying` whose contents should be an `int`.
  length: ->

  # The internal signature generation should return a `Varying` of the
  # signature.
  _signature: -> new Varying( value: '' )


# Cached lazy lists have some considerations: they should cache results in
# case multiple resolutions happen against the same range. They should also
# manage the cache and changes in list contents/definition. The cachekey
# generation happens assumedly from a set of parameters encoded in the List's
# attributes.
class CachedLazyList extends LazyList

  constructor: ->
    super()

    # In addition to tracking the active ranges, we'll want to track the
    # union of the coverage of those ranges.
    this._extCoverage = new Coverage()
    this._intCoverages = {}

    this._activeRanges.on('added', (range) => this._extCoverages.add(range))

    this._initSignature(this.get('signature'))

  _watchSignature: ->
    this.watch('signature').on 'changed', (signature) ->
      if this._intCoverages[signature]?
        # If we already have a coverage defined just use it.
        this._fetchRange(range) for range in this._activeRanges.list
      else
        # Otherwise init a new one.
        this._initSignature(signature)

  _initSignature: (signature) ->
    this._intCoverages[signature] = new Coverage()

    # Prefetch the continuous external ranges we know about.
    this.range(lower, upper) for [ lower, upper ] in this._extCoverages.fills()

    # Then bind the actual external ranges we have against it. Remember to wrap
    # inside the external-facing range.
    for range in this._activeRanges.list
      range.setValue(this._fetchRange(new Range(range.lower, range.upper, new List())))

    # Return nothing.
    null

  # We have entirely our own behavior for `range`; we want to track internal
  # and external coverages separately, and only delegate to `_range` for areas
  # of our internal coverage that we've missed. We then update external ranges
  # when relevant slices of our internal coverage update.
  #
  # I'm not super happy with this. It's leakier than I'd like.
  range: (lower, upper) ->
    result = new Range(lower, upper, new List())
    wrapped = wrapAndSealFate(result)

    this._fetchRange(result)
    this._activeRanges.add(wrapped)

    wrapped

  # Split out the actual fetching, caching behavior
  _fetchRange: (result) ->
    intCoverage = this._intCoverage[this.get('signature')]

    # First, retrieve the ranges that exist within our target range, populate
    # from them, and watch their updates.
    for range in intCoverage.within(lower, upper)
      do (range) ->
        update = rangeUpdater(range, result)
        update()
        range.on('changed', update)

    # Now, grab and request our gaps.
    gaps = intCoverage.gaps(lower, upper)
    for [ lower, upper ] in gaps
      do ->
        range = this._range(lower, upper)
        update = rangeUpdater(range, result)
        update()
        range.on('changed', update)

    # Return our result.
    result

util.extend(module.exports,
  LazyList: LazyList
  CachedLazyList: CachedLazyList
)

