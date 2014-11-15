DerivedList = require('./list').DerivedList
Varying = require('../core/varying').Varying
util = require('../util/util')

# A read-only view into a proper `List` that filters out nonqualifying
# elements. Doesn't yet respect positional stability from parent.
class FilteredList extends DerivedList
  constructor: (@parent, @isMember, @options = {}) ->
    super()

    this._filterers = []
    this._idxMap = []

    this._initElems(this.parent.list)

    this.parent.on('added', (elem, idx) => this._initElems(elem, idx))
    this.parent.on 'removed', (elem, idx) =>
      [ filterer ] = this._filterers.splice(idx, 1)
      [ oldIdx ] = this._idxMap.splice(idx, 1)

      if filterer.value is true
        this._removeAt(oldIdx)

        for adjIdx in [idx...this._idxMap.length]
          this._idxMap[adjIdx] -= 1

  _initElems: (elems, idx = this.list.length) ->
    elems = [ elems ] unless util.isArray(elems)

    newFilterers = (Varying.ly(this.isMember(elem)) for elem in elems)
    newMap = ((this._idxMap[idx - 1] ? -1) for _ in elems)

    Array.prototype.splice.apply(this._filterers, [ idx, 0 ].concat(newFilterers))
    Array.prototype.splice.apply(this._idxMap, [ idx, 0 ].concat(newMap))

    for filterer in newFilterers
      do (filterer) =>
        lastResult = false
        filterer.reactNow (result) =>
          idx = this._filterers.indexOf(filterer)
          return if idx is -1

          result = (result is true)
          unless result is lastResult
            idxAdj = if result is true then 1 else -1
            for adjIdx in [idx...this._idxMap.length]
              this._idxMap[adjIdx] += idxAdj

            if result is true
              this._add(this.parent.at(idx), this._idxMap[idx] ? 0)
            else
              this._removeAt(this._idxMap[idx])

            lastResult = result

    null

util.extend(module.exports,
  FilteredList: FilteredList
)

