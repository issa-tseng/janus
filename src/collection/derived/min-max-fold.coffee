{ Varying } = require('../../core/varying')
{ Base } = require('../../core/base')


class MinMaxFold extends Base
  constructor: (list, compare) ->
    super()

    find = ->
      candidate = list.at_(0)
      (candidate = x) for x in list.list when compare(x, candidate)
      candidate

    this._varying = new Varying(find())

    this.listenTo(list, 'added', (obj) =>
      if compare(obj, this._varying.get())
        this._varying.set(obj)
      return
    )

    this.listenTo(list, 'removed', (obj) =>
      if obj is this._varying.get()
        this._varying.set(find())
      return
    )

  @min: (list) -> Varying.managed((-> new MinMaxFold(list, (x, y) -> x < y)), (incl) -> incl._varying)
  @max: (list) -> Varying.managed((-> new MinMaxFold(list, (x, y) -> x > y)), (incl) -> incl._varying)

module.exports = { MinMaxFold }

