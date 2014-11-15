# in which liam neeson comes and beats in your face until you return the
# correct data structure.

DerivedList = require('./list').DerivedList
Varying = require('../core/varying').Varying
util = require('../util/util')

class TakenList extends DerivedList
  constructor: (@parent, @number) ->
    super()

    this.number = Varying.ly(this.number)
    this.number.react(=> this._rebalance())

    this._add(elem) for elem in this.parent.list
    this._rebalance()

    this.parent.on 'added', (elem, idx) =>
      this._add(elem, idx)
      this._rebalance()
    this.parent.on 'removed', (_, idx) =>
      this._removeAt(idx)
      this._rebalance()

  _rebalance: ->
    take = Math.min(this.number.value, this.parent.list.length)
    if this.list.length < take
      while this.list.length isnt take
        this._add(this.parent.at(this.list.length), this.list.length)
    else if this.list.length > take
      while this.list.length isnt take
        this._removeAt(take)
    null

util.extend(module.exports,
  TakenList: TakenList
)

