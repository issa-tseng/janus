{ Map, Model, bind, from } = require('janus')

oneOf = (xs...) ->
  (return x) for x in xs when x?
  return

class KVPair extends Model.build(
  bind('value', from('model').and('key').all.flatMap((m, k) -> m.get(k)))

  # a little timid on some of these for the sake of Maps so use ?
  bind('bound', from('model').and('key').all.map((m, k) -> m.constructor.schema?.bindings[k]?))
  bind('binding', from('model').and('key').all.map((m, k) -> m._bindings?[k]?.parent))
)

class WrappedModel extends Model.build(
    bind('type', from('model').map((model) -> if model.isModel then 'Model' else 'Map'))
    # TODO: don't add the dot here.
    bind('subtype', from('model')
      .map((model) -> model.constructor.name)
      .map((name) -> if name? and (name not in [ 'Model', 'Map', '_Class' ]) then ".#{name}" else ''))

    bind('identifier', from('model').get('name')
      .and('model').get('title')
      .and('model').get('label')
      .and('model').get('id')
      .and('model').get('uid')
      .all.map(oneOf))

    bind('pairs', from('model').map((model) -> model.enumerate().map((key) -> new KVPair({ model, key }))))
  )

  isInspector: true
  isWrappedModel: true
  constructor: (model, options) -> super({ model }, options)

  @wrap: (m) -> if (m.isWrappedModel is true) then m else (new WrappedModel(m))

module.exports = {
  WrappedModel,
  KVPair,
  registerWith: (library) ->
    library.register(Map, WrappedModel.wrap)
    library.register(Model, WrappedModel.wrap)
}

