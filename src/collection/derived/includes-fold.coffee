{ Varying } = require('../../core/varying')
{ Base } = require('../../core/base')


class IncludesFold extends Base
  constructor: (list, x) ->
    super()

    this._varying = new Varying(false)

    this.listenTo(list, 'added', (obj) =>
      if obj is this._value
        this._count += 1
        this._varying.set(true)
      return
    )

    this.listenTo(list, 'removed', (obj) =>
      if obj is this._value
        this._count -= 1
        if this._count is 0
          this._varying.set(false)
      return
    )

    this.reactTo(Varying.of(x), (value) =>
      this._value = value
      this._count = 0
      (this._count += 1) for x in list.list when x is value
      this._varying.set(this._count > 0)
      return
    )

  @includes: (list, x) -> Varying.managed((-> new IncludesFold(list, x)), (incl) -> incl._varying)

module.exports = { IncludesFold }

