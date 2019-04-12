{ Map, Model, bind, from } = require('janus')


################################################################################
# EXTENDED KEY LIST
# because enumerations only contain populate keys, we miss bindings that
# evaluate to nothing. so we need to create something to augment that.

# get a reference to the KeyList class (TODO: should we export these?)
keyList = (new Map()).enumerate()
KeyList = keyList.constructor
keyList.destroy()

class AllKeyList extends KeyList
  constructor: (target, options) ->
    super(target, options)

    # add all bindings if they haven't already been picked up.
    # _addKey already knows not to add duplicate keys.
    this._addKey(key) for key of target._bindings

  _removeKey: (key) ->
    super(key) unless this.target._bindings[key]?


################################################################################
# KEYPAIR MODEL
# represents a single key/value pair in a map/model

class KeyPair extends Model.build(
  bind('value', from('target').and('key').all.flatMap((t, k) -> t.get(k)))

  # a little timid on some of these for the sake of Maps so use ?
  bind('bound', from('target').and('key').all.map((t, k) -> t.constructor.schema?.bindings[k]?))
  bind('binding', from('target').and('key').all.map((t, k) -> t._bindings?[k]?.parent))
)

################################################################################
# MODEL INSPECTOR

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
  )

  isInspector: true
  isWrappedModel: true
  constructor: (target, options) -> super({ target }, options)

  enumerateAll: -> this.enumerateAll$ ?= new AllKeyList(this.get_('target'))
  pairsAll: -> this.pairsAll$ ?= do =>
    target = this.get_('target')
    this.enumerateAll().map((key) -> new KeyPair({ target, key }))
  @wrap: (m) -> if (m.isWrappedModel is true) then m else (new WrappedModel(m))


module.exports = {
  KeyPair, WrappedModel,
  registerWith: (library) ->
    library.register(Map, WrappedModel.wrap)
    library.register(Model, WrappedModel.wrap)
}

