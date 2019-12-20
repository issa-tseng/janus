{ Map, Set, Model, bind, from, List } = require('janus')


################################################################################
# EXTENDED KEY LIST
# because enumerations only contain populated keys, we miss bindings that
# evaluate to nothing. so we need to create something to augment that.

class AllKeySet extends Set
  constructor: (@parent) ->
    super()
    this._list.add(this.parent.enumerate_())
    Set.prototype.add.call(this, key) for key of this.parent._bindings
    Set.prototype.add.call(this, key) for key of schema.attributes if (schema = this.parent.constructor.schema)?

    this.listenTo(this.parent, 'changed', (key, newValue, oldValue) =>
      if newValue? and not oldValue?
        Set.prototype.add.call(this, key)
      else if oldValue? and not newValue? and not this.parent._bindings[key]?
        Set.prototype.remove.call(this, key)
      return
    )

  mapPairs: (f) -> this.flatMap((k) => Varying.mapAll(f, new Varying(k), this.parent.get(k)))
  flatMapPairs: (f) -> this.flatMap((k) => Varying.flatMapAll(f, new Varying(k), this.parent.get(k)))
  add: undefined
  remove: undefined


################################################################################
# KEYPAIR MODEL
# represents a single key/value pair in a map/model

class KeyPair extends Model.build(
  bind('value', from('target').and('key').all.flatMap((t, k) -> t.get(k)))

  # a little timid on some of these for the sake of Maps so use ?
  bind('bound', from('target').and('key').all.map((t, k) -> t.constructor.schema?.bindings[k]?))
  bind('binding', from('target').and('key').all.map((t, k) -> t._bindings?[k]?.parent))
)
  _initialize: ->
    this.set('attribute', this.get_('target').attribute?(this.get_('key')))

################################################################################
# MODEL INSPECTOR

oneOf = (xs...) ->
  (return x) for x in xs when x?
  return


class WrappedModel extends Model.build(
    bind('type', from('target').map((target) -> if target.isModel then 'Model' else 'Map'))
    bind('subtype', from('target')
      .map((target) -> target.constructor.name)
      .map((name) -> name if (name not in [ 'Model', 'Map', '_Class' ])))

    bind('identifier', from('target').get('name')
      .and('target').get('title')
      .and('target').get('label')
      .and('target').get('id')
      .and('target').get('uid')
      .all.map(oneOf))

    bind('parent', from('target').map((target) -> target._parent))
    bind('validations', from('target').map((target) ->
      if target.isModel is true then target.validations()
      else new List()))
  )

  isInspector: true
  isWrappedModel: true
  constructor: (target, options) -> super({ target }, options)

  enumerateAll: -> this.enumerateAll$ ?= new AllKeySet(this.get_('target'))
  pairsAll: -> this.pairsAll$ ?= do =>
    this.enumerateAll().map((key) => new KeyPair({ target: this.get_('target'), key }))
  @wrap: (m) -> if (m.isWrappedModel is true) then m else (new WrappedModel(m))


module.exports = {
  KeyPair, WrappedModel,
  registerWith: (library) ->
    library.register(Map, WrappedModel.wrap)
    library.register(Model, WrappedModel.wrap)
}

