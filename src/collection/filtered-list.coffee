List = require('./list').List
OrderedIncrementalList = require('./types').OrderedIncrementalList
Varying = require('../core/varying').Varying
util = require('../util/util')

# A read-only view into a proper `List` that filters out nonqualifying
# elements. Doesn't yet respect positional stability from parent.
class FilteredList extends OrderedIncrementalList
  constructor: (@parent, @isMember, @options = {}) ->
    super()

    # build our initial list off of the parent
    this.list = []
    this._initElems(this.parent.list)

    # general init hook.
    this._initialize?()

    # listen to our parent for changes.
    this.parent.on('added', (elem) => this._initElems(elem))
    this.parent.on('removed', (elem) => this._remove(elem))

  # Takes in elements and does a filter check against them. If a `Varying`
  # is returned, listens to the membership changes over time.
  _initElems: (elems) ->
    elems = [ elems ] unless util.isArray(elems)

    for elem in elems
      # run the isMember once and see what it gives us.
      result = this.isMember(elem)

      if result instanceof Varying
        do (elem) =>
          lastMembership = false # the element isn't current part of the list.

          # adds/removes the element given the new membership.
          handleChange = (newValue) =>
            membership = newValue is true
            if lastMembership isnt membership
              if membership is true
                this._add(elem)
              else
                this._remove(elem)
            lastMembership = membership

          result.on('changed', handleChange) # listen to changes.
          handleChange(result.value) # trigger instantly with current change.

      else if result is true
        # straight up add.
        this._add(elem)

    elems

  # Blindly add the given elements. Does no actual checking.
  _add: (elem) ->
    # drop in the new element and event.
    idx = this.list.length

    this.list.push(elem)
    this.emit('added', elem, idx)
    elem.emit?('addedTo', this, idx)

  # Remove the given element if it exists in our list.
  _remove: (elem) ->
    # find the element.
    idx = this.list.indexOf(elem)

    if idx >= 0
      # if we have an element we've actually added, take it out.
      removed = this.list.splice(idx, 1)[0]

      # event.
      this.emit('removed', removed, idx)
      removed.emit?('removedFrom', this, idx)

      removed

util.extend(module.exports,
  FilteredList: FilteredList
)

