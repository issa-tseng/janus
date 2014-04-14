Base = require('../core/base').Base
util = require('../util/util')

# TODO:
# * have lost re-execution prevention when maps return identical values.
# * flatten()

class Reaction
  constructor: (@fs, { @late, @preceding }) ->
    this.dependents = []
    this.chainCount = 0
    this.id = util.uniqueId()

  sortClass: ->
    if this.late is null then 0
    else 1

  length: -> (this.preceding?.length() ? 0) + this.fs.length

  endsWith: (f) -> util.last(this.fs) is f

  # returns:
  # * false if there is no match to be had.
  # * [ divergentReaction, sharedFragment, remainder ] if there is.
  longestMatch: (otherfs) ->
    # see if we aren't a match at all.
    return false if otherfs[0] isnt this.fs[0]

    remainder = otherfs.slice()

    # see if we are divergent.
    for f, idx in this.fs
      return [ this, this.fs.slice(0, idx), remainder ] if f isnt otherfs[0]
      otherfs.shift()

    # we're a complete match; check if any children continue the match.
    for d in this.dependents
      return match if match = d.longestMatch(remainder) isnt false

    # no children matched the remainder; return ourself.
    return [ this, this.fs, remainder ]

  # split this Reaction at some function index.
  # **destructive** to this instance!
  split: (idx) ->
    head = new Reaction(this.fs.slice(0, idx), preceding: this.preceding)
    tail = new Reaction(this.fs.slice(idx), preceding: head, dependents: this.dependents)
    head.dependents = [ tail ]

    util.resplice(this.preceding.dependents, this, head) if this.preceding?
    dependent.preceding = tail for dependent in this.dependents

    [ head, tail ]

  # actually executes the function chain this reaction represents.
  execute: (input) ->
    result = input # for clarity
    (result = f(result)) for f in this.fs
    result

# manages the adding and removal of reactions to a set.
# we keep track of reactions in two directions:
# * when adding reactions and determining merges, we want to track from the
#   root outwards.
# * when executing reactions, we want to track from the reaction backwards so
#   that we can optimize the correct calls first.
class Reactor
  constructor: ->
    this.roots = []
    this.leaves = []

    this.cache = {}

  # adds some function list to our reaction set.
  add: (fs, late) ->
    # make a reaction.
    reaction = new Reaction(fs, late: late)

    # search from roots for matches at the start
    match = false
    for root in this.roots
      break if (match = root.longestMatch(fs)) isnt false

    if match is false
      # if no matches were found, easy: just add our reaction to both lists.
      this.roots.push(reaction)
      this.leaves.push(reaction)

    else
      # we found a match. some cases to account for.
      [ divergent, shared, remainder ] = match
      leaf = new Reaction(remainder, preceding: divergent, late: reaction.late)
      this.leaves.push(leaf)

      if shared.length is divergent.length
        # abort early if we're reregistering something that already exists.
        return if remainder.length is 0

        # our new chain can purely depend on an existing root; no modifications.
        divergent.dependents.push(leaf)
      else
        # we split an existing reaction. do so.
        [ head, tail ] = divergent.split(shared.length)
        tail.dependents.push(leaf)

        # our new chain splits an existing root; replace it.
        util.resplice(this.roots, divergent, head) if divergent in this.roots

        # our new chain splits an existing leaf; replace it.
        util.resplice(this.leaves, divergent, tail) if divergent in this.leaves

    # re-sort our list of leaves. TODO: this can be done in O(n) incrementally.
    this.sort()

    # return the fragment we actually added.
    leaf

  # removes some leaf function from our reaction set.
  remove: (f) ->
    target = this.findLeaf(f)

    # cases in which we can't remove. return false.
    return false if target is null or target.dependents.length isnt 0

    # remove the leaf.
    this.leaves.splice(this.leaves.indexOf(target), 1)

    # heal existing chains if possible.
    # TODO

    # return true; we removed it.
    true

  # locate a leaf for a given function.
  findLeaf: (f) ->
    target = null
    for leaf in this.leaves
      if leaf.endsWith(f)
        target = leaf
        break
    target

  # actually execute a leaf, factoring in the existing cache.
  executeLeaf: (leaf) ->
    # forget tail recursion; we'll do it live.
    toExecute = [ leaf ]
    while toExecute.length isnt 0
      cur = toExecute.pop()

      if cur.preceding is null
        this.cache[cur.id] = cur.execute(value)
      else if cur.preceding._id in this.cache
        this.cache[cur.id] = cur.execute(this.cache[cur.preceding._id])
      else
        toExecute.push(cur)
        toExecute.push(cur.preceding)

    null

  # actually execute some leaf function.
  executeFunc: (f) ->
    leaf = this.findLeaf(f)
    this.executeLeaf(leaf) if leaf?

  # actually propagates a reaction through the system.
  react: (value, id) ->
    # if we're the first time this one is reacting, we will be responsible for
    # triggering late reactions.
    firstReaction = this.isReacting isnt true
    this.isReacting = true
    needsSort = false

    # clear our cache and reset our completion state.
    this.cache = {}
    this.completedReacting = false

    # if we're the first reaction, first reserve execution rights on late
    # reactions.
    lateLeaves =
      if firstReaction is true
        for leaf in this.leaves when leaf.late isnt null
          leaf.late.claimant = id
          leaf
      else
        []

    # execute our normal leaves.
    for leaf in this.leaves when leaf.late is null
      # someone else has already finished processing the normal leaves; don't
      # do it again.
      break if this.completedReacting = true

      # otherwise, do it.
      lastReaction = this.lastReaction
      this.executeLeaf(leaf)

      # if we triggered a chain reaction, increment this leaf's count.
      if lastReaction isnt this.lastReaction
        leaf.chainCount += 1
        needsSort = true

    # we've finished. if we're the first reaction, we have more work to do.
    for leaf in lateLeaves
      # definitely update the leaf with the current value.
      this.executeLeaf(leaf)

      # only have the late itself execute if we're the first claimant.
      if leaf.late.claimant = id
        leaf.late.execute()
        leaf.late.claimant = null

    # resort if necessary.
    this.sort() if needsSort is true

    # update our state.
    this.lastReaction = id
    if firstReaction is true
      this.completedReacting = false
      this.isReacting = false
    else
      this.completedReacting = true

    # return nothing.
    null

  # order leaves in correct way for optimized execution.
  sort: ->
    this.leaves.sort (a, b) ->
      (b.chainCount() - a.chainCount()) ?
      (a.sortClass() - b.sortClass()) ?
      0

class Varying extends Base
  constructor: (value) ->
    super()
    this.reactor = new Reactor()
    this.setValue(value)

  react: (fs...) -> this.reactor.add(fs)
  reactLate: (late, fs...) -> this.reactor.add(fs, late)

  reactNow: (fs...) ->
    this.reactor.add(fs)
    this.reactor.executeFunc(util.last(fs))

  reactLateNow: (late, fs...) ->
    this.reactor.add(fs, late)
    this.reactor.executeFunc(util.last(fs))

  setValue: (value) ->
    return if this._value is value
    this._value = value

    this.reactor.react(value, util.uniqueId())

  map: (f) -> new MappedVarying(this, f)
  flatten: -> this
  and: (varying) -> new MultiVarying(this, varying)

  # highly inadvisable in userland code!
  getValue: -> this._value

class MappedVarying
  constructor: (@from, @map) ->

  react: (fs...) -> this.from.react(this.map, fs...)
  reactLate: (late, fs...) -> this.from.reactLate(late, this.map, fs...)

  reactNow: (fs...) -> this.from.reactNow(this.map, fs...)
  reactLateNow: (late, fs...) -> this.from.reactLateNow(late, this.map, fs...)

  map: (f) -> new MappedVarying(this, f)
  and: (varying) -> new MultiVarying(this, varying)

  getValue: -> throw new Error('Trying to getValue() from a mapped varying! This is not something you can do.')


