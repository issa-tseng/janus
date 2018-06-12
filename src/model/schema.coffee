{ isFunction } = require('../util/util')
{ Attribute } = require('./attribute')

TransientAttribute = class extends Attribute
  transient: true

module.exports = {
  attribute: (key, klass) -> (schema) -> schema.attributes[key] = klass
  bind: (key, binding) -> (schema) -> schema.bindings[key] = binding
  issue: (binding) -> (schema) -> schema.issues.push(binding)

  transient: (key) -> (schema) -> schema.attributes[key] = TransientAttribute
  default: (key, value, klass = Attribute) -> (schema) ->
    wrapped = if isFunction(value) then value else (-> value)
    schema.attributes[key] = class extends klass
      default: wrapped

  Trait: (parts...) -> (schema) ->
    part(schema) for part in parts
    null
}

