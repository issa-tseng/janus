
util = require('../util/util')
Model = require('./model').Model

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

  # Model tries to be clever about its children; here we assume by default we
  # *are* a child.
  @deserialize: (data) -> data

class TextAttribute extends Attribute

class EnumAttribute extends Attribute
  values: -> []

class NumberAttribute extends Attribute

class DateAttribute extends Attribute
  @deserialize: (data) -> new Date(data)

class ModelAttribute extends Attribute
  @modelClass: Model

  @deserialize: (data) ->
    this.modelClass.deserialize(data)

class CollectionAttribute extends Attribute
  @collectionClass: Array
  @modelClass: Object

  @deserialize: (data) ->
    models =
      if this.modelClass.prototype instanceof Model
        this.modelClass.deserialize(datum) for datum in data
      else
        data

    new (this.collectionClass)(models)


util.extend(module.exports,
  Attribute: Attribute

  TextAttribute: TextAttribute
  EnumAttribute: EnumAttribute
  NumberAttribute: NumberAttribute
  DateAttribute: DateAttribute
  ModelAttribute: ModelAttribute
  CollectionAttribute: CollectionAttribute
)

