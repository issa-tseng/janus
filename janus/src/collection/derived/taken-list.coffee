# in which liam neeson comes and beats in your face until you return the
# correct data structure.

{ min, max } = Math
DerivedList = require('../list').DerivedList
Varying = require('../../core/varying').Varying


class TakenList extends DerivedList
  constructor: (@parent, @number) ->
    super()

    this.number = Varying.of(this.number)
    this.reactTo(this.number, false, => this._rebalance())

    take = this._take()
    this._add(elem, idx) for elem, idx in this.parent.list when idx < take

    this.listenTo(this.parent, 'added', (elem, idx) => this._add(elem, idx))
    this.listenTo(this.parent, 'moved', (elem, idx, oldIdx) => this._moveElem(elem, oldIdx, idx))
    this.listenTo(this.parent, 'removed', (_, idx) => this._removeAt(idx))

  _take: ->
    number = this.number.get()
    if number < 0 then max(0, this.parent.list.length + number)
    else min(this.number.get(), this.parent.list.length)

  _add: (elem, idx, take = this._take()) ->
    super([ elem ], idx) if idx < take # don't add phantom elements far past the end.
    this._removeAt(take) if this.list.length > take
    return

  _moveElem: (elem, oldIdx, newIdx) ->
    take = this._take()
    if oldIdx < take
      if newIdx < take
        this._moveAt(oldIdx, newIdx)
      else
        this._removeAt(oldIdx)
    else if newIdx < take
      this._add(elem, newIdx)
    return

  _removeAt: (idx) ->
    super(idx)
    this._add(this.parent.list[this.list.length], this.list.length) if this.list.length < this._take()
    return

  _rebalance: ->
    take = this._take()
    if this.list.length < take
      this._add(this.parent.at_(this.list.length), this.list.length) while this.list.length isnt take
    else if this.list.length > take
      this._removeAt(take) while this.list.length isnt take
    return


module.exports = { TakenList }

