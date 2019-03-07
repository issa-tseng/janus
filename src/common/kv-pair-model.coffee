{ Model, bind, from } = require('janus')

class KVPair extends Model.build(
  bind('value', from('target').and('key').all.flatMap((t, k) -> t.get(k)))

  # a little timid on some of these for the sake of Maps/Lists so use ?
  bind('bound', from('target').and('key').all.map((t, k) -> t.constructor.schema?.bindings[k]?))
  bind('binding', from('target').and('key').all.map((t, k) -> t._bindings?[k]?.parent))
)

module.exports = { KVPair }

