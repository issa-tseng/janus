{ Map, Model, bind, from } = require('janus')
{ KVPair } = require('../common/kv-pair-model')

oneOf = (xs...) ->
  (return x) for x in xs when x?
  return

class WrappedModel extends Model.build(
    bind('type', from('target').map((target) -> if target.isModel then 'Model' else 'Map'))
    # TODO: don't add the dot here.
    bind('subtype', from('target')
      .map((target) -> target.constructor.name)
      .map((name) -> if name? and (name not in [ 'Model', 'Map', '_Class' ]) then ".#{name}" else ''))

    bind('identifier', from('target').get('name')
      .and('target').get('title')
      .and('target').get('label')
      .and('target').get('id')
      .and('target').get('uid')
      .all.map(oneOf))

    bind('pairs', from('target').map((target) -> target.enumerate().map((key) -> new KVPair({ target, key }))))
  )

  isInspector: true
  isWrappedModel: true
  constructor: (target, options) -> super({ target }, options)

  @wrap: (m) -> if (m.isWrappedModel is true) then m else (new WrappedModel(m))

module.exports = {
  WrappedModel,
  KVPair,
  registerWith: (library) ->
    library.register(Map, WrappedModel.wrap)
    library.register(Model, WrappedModel.wrap)
}

