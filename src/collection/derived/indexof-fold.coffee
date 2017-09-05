{ Varying } = require('../../core/varying')
{ Base } = require('../../core/base')


class IndexOfFold extends Base
  constructor: (list, x) ->
    super()

    this._list = list
    this._varying = new Varying(-1)

    this.listenTo(this._list, 'added', (obj, idx) => this._addObj(obj, idx))
    this.listenTo(this._list, 'moved', (obj, idx, oldIdx) => this._moveObj(obj, idx, oldIdx))
    this.listenTo(this._list, 'removed', (obj, idx) => this._removeObj(obj, idx))

    this._targetObservation = Varying.ly(x).react((value) => this._handleValue(value))

  _handleValue: (value) ->
    this._value = value
    this._set(this._list.list.indexOf(value))

  _addObj: (obj, idx) ->
    if (obj is this._value) and ((idx < this._lastIdx) or (this._lastIdx is -1))
      this._set(idx)
    else if idx <= this._lastIdx
      this._set(this._lastIdx + 1)

  _moveObj: (obj, idx, oldIdx) ->
    if oldIdx is this._lastIdx
      this._set(idx)
    else if (idx <= this._lastIdx) and (oldIdx > this._lastIdx)
      this._set(this._lastIdx + 1)
    else if (idx >= this._lastIdx) and (oldIdx < this._lastIdx)
      this._set(this._lastIdx - 1)

  _removeObj: (obj, idx) ->
    if idx is this._lastIdx
      this._set(this._list.list.indexOf(this._value))
    else if idx < this._lastIdx
      this._set(this._lastIdx - 1)

  _set: (idx) ->
    this._lastIdx = idx
    this._varying.set(idx)

  _destroy: -> this._targetObservation.stop()

  @indexOf: (list, x) -> Varying.managed((-> new IndexOfFold(list, x)), ((iof) -> iof._varying))


module.exports = { IndexOfFold }

