from = require('../core/from')
{ Model } = require('./model')
{ Struct } = require('../collection/struct')
{ Varying } = require('../core/varying')
{ List } = require('../collection/list')


# This derivation theoretically means that `Attributes` can contain schemas,
# which means they can in turn produce `Attributes`. The universe-ending
# implications of this design quirk are left as an exercise to the implementeur.
class Attribute extends Model
  constructor: (@model, @key) -> super()

  setValue: (value) -> this.model.set(this.key, value)
  unsetValue: -> this.model.unset(this.key)
  getValue: ->
    value = this.model.get(this.key)
    if !value? and this.default?
      value = this.default()
      if this.writeDefault is true
        this.setValue(value)
    value

  watchValue: -> this.model.watch(this.key)

  default: ->
  writeDefault: false # set to true to write-on-get the default stated above.

  transient: false # set to true to never diff or serialize this attribute.

  # Model tries to be clever about its children; here we assume by default we
  # *are* a child.
  @deserialize: (data) -> data

  # default implementation just spits out the value, unless we're transient.
  serialize: -> this.getValue() unless this.transient is true

class TextAttribute extends Attribute

class EnumAttribute extends Attribute
  values: -> new List([])
  nullable: false

class NumberAttribute extends Attribute

class BooleanAttribute extends Attribute

class DateAttribute extends Attribute
  @deserialize: (data) -> new Date(data)
  serialize: -> this.getValue()?.getTime() unless this.transient is true

class ModelAttribute extends Attribute
  @modelClass: Model

  writeDefault: true

  @deserialize: (data) -> this.modelClass.deserialize(data)
  serialize: -> this.constructor.modelClass.serialize(this.getValue()) unless this.transient is true

class CollectionAttribute extends Attribute
  @collectionClass: List

  writeDefault: true

  @deserialize: (data) -> this.collectionClass.deserialize(data)
  serialize: -> this.constructor.collectionClass.serialize(this.getValue()) unless this.transient is true

class ReferenceAttribute extends Attribute
  isReference: true
  transient: true

  # By default, you should only have to provide a request-given-a-model and the
  # default resolver implementation will take care of everything just fine. But
  # if you need custom handling you can go the other way around and just write a
  # custom resolver.
  request: -> null
  resolver: ->
    from.varying(new Varying(this.request()))
      .and.app()
      .all.flatMap((request, app) -> app.getStore(request).handle(); request)

  @contains: Model
  @deserialize: (data) -> this.contains.deserialize(data)


module.exports = {
  Attribute: Attribute

  TextAttribute: TextAttribute
  EnumAttribute: EnumAttribute
  NumberAttribute: NumberAttribute
  BooleanAttribute: BooleanAttribute
  DateAttribute: DateAttribute
  ModelAttribute: ModelAttribute
  CollectionAttribute: CollectionAttribute
  ReferenceAttribute: ReferenceAttribute
}

