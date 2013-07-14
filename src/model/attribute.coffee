
util = require('../util/util')
Model = require('./model').Model
List = require('../collection/list').List

# This derivation theoretically means that `Attributes` can contain schemas,
# which means they can in turn produce `Attributes`. The universe-ending
# implications of this design quirk are left as an exercise to the implementeur.
class Attribute extends Model
  constructor: (@model, @key) ->
    super()
    this._initialize?()

  setValue: (value) -> this.model.set(this.key, value)
  getValue: -> this.model.get(this.key)

  watchValue: -> this.model.watch(this.key)

  default: ->
  writeDefault: false # set to true to write-on-get the default stated above.

  # Model tries to be clever about its children; here we assume by default we
  # *are* a child.
  @deserialize: (data) -> data

class TextAttribute extends Attribute

class EnumAttribute extends Attribute
  values: -> new List([])

class NumberAttribute extends Attribute

class DateAttribute extends Attribute
  @deserialize: (data) -> new Date(data)

class ModelAttribute extends Attribute
  @modelClass: Model

  @deserialize: (data) -> this.modelClass.deserialize(data)
  serialize: -> this.constructor.modelClass.serialize(this.getValue())

class CollectionAttribute extends Attribute
  @collectionClass: Array

  @deserialize: (data) -> this.collectionClass.deserialize(data)


util.extend(module.exports,
  Attribute: Attribute

  TextAttribute: TextAttribute
  EnumAttribute: EnumAttribute
  NumberAttribute: NumberAttribute
  DateAttribute: DateAttribute
  ModelAttribute: ModelAttribute
  CollectionAttribute: CollectionAttribute
)

