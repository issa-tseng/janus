
util = require('../util/util')
from = require('../core/from')
Model = require('./model').Model
Varying = require('../core/varying').Varying
List = require('../collection/list').List


# This derivation theoretically means that `Attributes` can contain schemas,
# which means they can in turn produce `Attributes`. The universe-ending
# implications of this design quirk are left as an exercise to the implementeur.
class Attribute extends Model
  constructor: (@model, @key) ->
    super()

    this.model = new ShellModel(this) unless this.model?

    this._initialize?()

  setValue: (value) -> this.model.set(this.key, value)
  unsetValue: -> this.model.unset(this.key)
  getValue: ->
    value = this.model.get(this.key, true)
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

class ObjectAttribute extends Attribute

class EnumAttribute extends Attribute
  values: -> new List([])
  nullable: false

class NumberAttribute extends Attribute

class BooleanAttribute extends Attribute

class DateAttribute extends Attribute
  @deserialize: (data) -> new Date(data)

class ModelAttribute extends Attribute
  @modelClass: Model

  @deserialize: (data) -> this.modelClass.deserialize(data)
  serialize: -> this.constructor.modelClass.serialize(this.getValue()) unless this.transient is true

class CollectionAttribute extends Attribute
  @collectionClass: Array

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


# Useful for creating standalone `Attribute`s that don't depend on a parent
# `Model` for databinding; usually for transient vars in `View`s.
#
# TODO: is there a less duplicative way of creating this pattern?
class ShellModel
  constructor: (@attribute) ->

  get: ->
    if this._value?
      this._value
    else if this.attribute.default?
      this.attribute.default()
    else
      null

  set: (_, value) ->
    this._value = value
    this._watcher?.setValue(value)

  watch: ->
    this._watcher ?= new Varying(this._value)


util.extend(module.exports,
  Attribute: Attribute

  TextAttribute: TextAttribute
  ObjectAttribute: ObjectAttribute
  EnumAttribute: EnumAttribute
  NumberAttribute: NumberAttribute
  BooleanAttribute: BooleanAttribute
  DateAttribute: DateAttribute
  ModelAttribute: ModelAttribute
  CollectionAttribute: CollectionAttribute
  ReferenceAttribute: ReferenceAttribute

  ShellModel: ShellModel
)

