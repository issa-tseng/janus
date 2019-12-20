{ Map, Set, Model, bind, from, List, Varying } = require('janus')


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

class MappedKeyPair extends KeyPair.build(
  bind('parent-value', from('target').and('key').all.flatMap((t, k) -> t._parent.get(k)))
  bind('mapper', from('target').map((t) -> t._mapper)))

class BoundKeyPair extends KeyPair.build(
  bind('bound', from(Varying.of(true))))

################################################################################
# MODEL INSPECTOR

oneOf = (xs...) ->
  (return x) for x in xs when x?
  return


class ModelInspector extends Model.build(
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
  isModelInspector: true
  constructor: (target, options) -> super({ target }, options)
  PairClass: KeyPair

  enumerateAll: -> this.enumerateAll$ ?= new AllKeySet(this.get_('target'))
  pairsAll: -> this.pairsAll$ ?= do =>
    this.enumerateAll().map((key) => new (this.PairClass)({ target: this.get_('target'), key }))
  @inspect: (m) ->
    if (m.isModelInspector is true) then m
    else if (m.isDerivedMap is true)
      if m._bindings? then new ModelInspector.FlatMapped(m)
      else new ModelInspector.Mapped(m)
    else new ModelInspector(m)

########################################
# DERIVED MAP TYPES

ModelInspector.Mapped = class extends ModelInspector.build(
  bind('subtype', from(Varying.of('Mapped'))))
  isTargetDerived: true
  PairClass: MappedKeyPair

ModelInspector.FlatMapped = class extends ModelInspector.build(
  bind('subtype', from(Varying.of('FlatMapped'))))
  isTargetDerived: true
  PairClass: BoundKeyPair


module.exports = {
  KeyPair, MappedKeyPair, BoundKeyPair, ModelInspector,
  registerWith: (library) ->
    library.register(Map, ModelInspector.inspect)
    library.register(Model, ModelInspector.inspect)
}

