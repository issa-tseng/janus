DerivedList = require('./list').DerivedList
Varying = require('../core/varying').Varying
util = require('../util/util')

# A read-only view into a proper `List` that filters out nonqualifying
# elements. Doesn't yet respect positional stability from parent.
class FilteredList extends DerivedList
  constructor: (@parent, @isMember, @options = {}) ->
    super()

    # build our initial list off of the parent
    this._initElems(this.parent.list)

    # general init hook.
    this._initialize?()

    # listen to our parent for changes.
    this.parent.on('added', (elem) => this._initElems(elem))
    this.parent.on('removed', (_, idx) => this._removeAt(idx))

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
          result.reactNow (membership) =>
            if lastMembership isnt membership
              if membership is true
                this._add(elem)
              else
                this._removeAt(this.list.indexOf(elem))
              lastMembership = membership

      else if result is true
        # straight up add.
        this._add(elem)

    elems

util.extend(module.exports,
  FilteredList: FilteredList
)

