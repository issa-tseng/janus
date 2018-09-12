{ Varying } = require('../../core/varying')
{ identity } = require('../../util/util')

AnyFold = {
  any: (list, f) -> Varying.managed(
    (-> if f? then list.flatMap(f) else list.tap()),
    (intermediate) -> intermediate.includes(true)
  )
}

module.exports = { AnyFold }

