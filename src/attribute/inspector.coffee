{ Model, Map, attribute, bind, from } = require('janus')
{ KVPair } = require('../common/kv-pair-model')

# minified code chews up class constructor names. thankfully, in this case we
# usually know exactly what the classes are so we can map them directly:
nameFor = (obj) ->
  if obj instanceof attribute.Text then 'TextAttribute'
  else if obj instanceof attribute.Enum then 'EnumAttribute'
  else if obj instanceof attribute.Number then 'NumberAttribute'
  else if obj instanceof attribute.Boolean then 'BooleanAttribute'
  else if obj instanceof attribute.Date then 'DateAttribute'
  else if obj instanceof attribute.Model then 'ModelAttribute'
  else if obj instanceof attribute.List then 'ListAttribute'
  else if obj instanceof attribute.Reference then 'ReferenceAttribute'
  else obj.constructor.name ? 'Attribute'

class AttributeInspector extends Model.build(
    # we do some extra work here to be sure we aren't causing side-effects:
    bind('value', from('target').and('key').all.flatMap((t, k) ->
      Map.prototype.get.call(t.model, k)))
    bind('pairs', from('target').map((target) -> target.enumerate().map((key) -> new KVPair({ target, key }))))
    bind('enum-values', from('target').flatMap((t) ->
      return unless t instanceof attribute.Enum
      # TODO: feels like the enum attribute itself should be doing this.
      values = t.values()
      if values?.all? then values.all.point(t.model.pointer()) if values?.all?
      else values
    ))
  )

  isInspector: true
  isAttributeInspector: true
  constructor: (target, options) ->
    super({ target, parent: target.model, type: nameFor(target), key: target.key }, options)

  @inspect: (a) -> new AttributeInspector(a)

module.exports = {
  AttributeInspector,
  registerWith: (library) -> library.register(attribute.Attribute, AttributeInspector.inspect)
}

