# Some classes that help track ranges of indices and their coverage, continuous
# or discontinuous.
#
# TODO: i don't like the mixed mutability.

util = require('./util')



# A `Coverage` represents the full set of runs covered by a collection of
# `Range`s. It's secretly a big ol tree.
class Coverage
  constructor: (children = []) ->
    this.children = []
    this.with(child) for child in children

  # Take some `Range` or other `Coverage` and include it in this `Coverage`.
  _with: (range) ->
    # if we can merge the range with an existing set, do so. we then want to
    # attempt merging the result against everything remaining in case the other
    # end of the bound also triggers a merge.
    while (idx = this._searchOverlap(range))?
      range = this.children.splice(idx, 1)._with(range)

    # whether we ended up merging or not, we want to accept this child.
    this.children.push(range)

    # and then we want to update our bounds
    this.lower = Math.min(this.lower ? range.lower, range.lower)
    this.upper = Math.max(this.upper ? range.upper, range.upper)

    # now we want to make sure we know if our range splits, so that we may
    # correctly deal with it.
    range.on 'split', (newCoverage) =>
      idx = this.children.indexOf(range)

      # if we don't know about the range anymore, abandon it.
      # TODO: probably better if this happens nonlazily.
      if idx < 0
        range.destroy()
      else
        this.children[idx] = newCoverage

    # We mutate in-place for new children, so just return self.
    this

  # We want to explose a verb that reflects the method's mutability:
  add: this.prototype._with

  # Check if we overlap some range.
  overlaps: (lower, upper) -> (lower <= this.upper) and (upper >= this.lower)

  # Get the set of `Range` objects within this `Coverage` that overlap some
  # particular bounds.
  within: (lower = this.lower, upper = this.upper) ->
    util.foldLeft([])(this.children, (result, child) ->
      result.concat(
        if !child.overlaps(lower, upper)
          []
        else if child instanceof Range
          [ child ]
        else
          child.within(idx, length)
      )
    )

  # Get the set of bounds that are not covered by this `Coverage` within some
  # given bounds. This is useful if we need to fill in some coverage but the
  # fill operation is expensive, and we want to eliminate repeated work.
  gaps: (lower = this.lower, upper = this.upper) ->
    # Apply a sort for this operation, since it simplifies the resulting work.
    this.children.sort((a, b) -> a.lower - b.lower)

    # Now go through and figure out what our gaps are
    gaps = []
    for child in this.children
      # First, see if we have produced a gap before this range.
      if lower < child.lower
        gaps.push([ lower, child.lower - 1 ])
        lower = child.lower

      # Now, examine the range itself, and figure out the action if we're
      # within it.
      if lower < child.upper
        if (child instanceof Range) or (child instanceof Continuous)
          lower = child.upper + 1
        else
          gaps = gaps.concat(child.gaps(lower, upper))
          lower = child.upper + 1

      # Clear out if we're done.
      break if lower >= upper

    # Take care of the tail end of the range.
    gaps.push([ lower, upper ]) if lower < upper

    # Done.
    gaps

  # Get the set of bounds that are actually covered by this `Coverage` within
  # the specified bounds.
  fills: (lower = this.lower, upper = this.upper) ->
    # Apply a sort for this operation, since it simplifies the resulting work.
    util.foldLeft([])(this.children, (result, child) ->
      result.concat(
        if !child.overlaps(lower, upper)
          []
        else if (child instanceof Continuous) or (child instanceof Range)
          [ child.lower, child.upper ]
        else
          child.fills(lower, upper)
      )
    )

  # Pull out the search for overlaps into a helper. This method somewhat
  # terribly depends on undefined comparing against all numbers as false
  # in the case that we are adding our very first element.
  _searchOverlap: (range) ->
    (return idx) for child, idx in this.children when child.overlaps(range.lower, range.upper)
    null


# A `Continuous` represents a continuously covered run by one or more `Ranges`.
# All operations on `Continuous` return either new `Continuous`s or `Coverage`s.
#
# This is largely a "clever" way of leveraging subclass implementation to
# automatically infer the contents of a subtree.
class Continuous extends Coverage
  constructor: (@children = []) ->
    this.lower = util.reduceLeft((child.lower for child in this.children), Math.min)
    this.upper = util.reduceLeft((child.upper for child in this.children), Math.max)

    # If we lose a range, let our parents know.
    for range in this.children
      do (range) =>
        range.on('destroying', => this.emit('split', this._without(range)))

  # By this point in the recursion, if we're being called we know we overlap.
  _with: (range) -> new Continuous(this.children.concat[ range ])

  # Only ever called internally.
  _without: (deadRange) -> new Coverage(range for range in this.children when range isnt deadRange)


# We want to track what range of the list our results are supposed to cover
# so that we can adjust them correctly when our list changes.
class Range extends Varying
  constructor: (@lower, @upper, value) ->
    super( value: value )

  # Check if we overlap some range.
  overlaps: (lower, upper) -> (lower <= this.upper) and (upper >= this.lower)

  # if we're being called, we're definitely continuous.
  _with: (other) -> new Continuous([ this, other ])



util.extend(module.exports,
  Coverage: Coverage
  Continuous: Continuous
  Range: Range
)

