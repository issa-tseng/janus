{ Varying } = require('../../core/varying')
{ Base } = require('../../core/base')


class SumFold extends Base
  constructor: (list) ->
    super()

    sum = 0
    (sum += x) for x in list.list

    this._varying = new Varying(sum)

    this.listenTo(list, 'added', (obj) =>
      this._varying.set(this._varying.get() + (obj ? 0))
      return
    )

    this.listenTo(list, 'removed', (obj) =>
      this._varying.set(this._varying.get() - (obj ? 0))
      return
    )

  @sum: (list) -> Varying.managed((-> new SumFold(list, (x, y) -> x < y)), (incl) -> incl._varying)

module.exports = { SumFold }

