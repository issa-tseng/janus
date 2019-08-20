from = require('../core/from')
types = require('../core/types')
{ Model } = require('./model')
{ Map } = require('../collection/map')
{ Varying } = require('../core/varying')
{ List } = require('../collection/list')
{ isFunction, isArray } = require('../util/util')


# This derivation theoretically means that `Attributes` can contain schemas,
# which means they can in turn produce `Attributes`. The universe-ending
# implications of this design quirk are left as an exercise to the implementeur.
class Attribute extends Model
  constructor: (@model, @key) -> super()

  setValue: (value) -> this.model.set(this.key, value)
  unsetValue: -> this.model.unset(this.key)
  getValue_: ->
    # TODO: this logic is only necessary if the model doesn't actually know about
    # the attribute.. should we just nix it?
    value = this.model.get_(this.key)
    if !value? and this.initial?
      value = this.initial()
      if this.writeInitial is true
        this.setValue(value)
    value

  getValue: -> this.model.get(this.key)

  initial: ->
  writeInitial: false # set to true to write-on-get the initial stated above.

  transient: false # set to true to never diff or serialize this attribute.

  # Model tries to be clever about its children; here we assume by default we
  # *are* a child.
  @deserialize: (data) -> data

  # default implementation just spits out the value, unless we're transient.
  serialize: -> this.getValue_() unless this.transient is true

class TextAttribute extends Attribute

class EnumAttribute extends Attribute
  values: -> this.values$ ?= do =>
    vs = this._values()
    vs = vs.all.point(this.model.pointer()) if vs?.all?
    Varying.of(vs).map((xs) ->
      if !xs? then new List()
      else if isArray(xs) then new List(xs)
      else if xs.isMappable then xs
      else new List()
    )

  _values: -> new List([])
  nullable: false

class NumberAttribute extends Attribute

class BooleanAttribute extends Attribute

class DateAttribute extends Attribute
  @deserialize: (data) -> new Date(data)
  serialize: -> this.getValue_()?.getTime() unless this.transient is true

# TODO: here and in ListAttribute, we ignore the value's own inherited serialize
# method and explicitly call the declared modelClass/listClass prototype on the
# data. but we don't do that for the recursive versions because we don't have that
# declaration. this inconsistency is weird and scary but also changing how serialize
# works can be scary too. and possibly serialize deals with null values?
class ModelAttribute extends Attribute
  modelClass: Model

  writeInitial: true

  @deserialize: (data) -> this.prototype.modelClass.deserialize(data)
  serialize: -> this.modelClass.prototype.serialize.call(this.getValue_()) unless this.transient is true

  @of: (modelClass) -> class extends this
    modelClass: modelClass
  @withInitial: -> class extends this
    initial: -> new (this.modelClass)()

  @Recursive: class RecursiveModelAttribute extends Attribute
    writeInitial: true
    @deserialize: (data, klass) -> klass.deserialize(data)
    serialize: -> this.getValue_()?.serialize() unless this.transient is true
    @withInitial: -> class extends this
      initial: -> new (this.model.constructor)()

class ListAttribute extends Attribute
  listClass: List

  writeInitial: true

  @deserialize: (data) -> this.prototype.listClass.deserialize(data)
  serialize: -> this.listClass.prototype.serialize.call(this.getValue_()) unless this.transient is true

  @of: (listClass) -> class extends this
    listClass: listClass
  @withInitial: -> class extends this
    initial: -> new (this.listClass)()

  @Recursive: class RecursiveListAttribute extends Attribute
    writeInitial: true
    @deserialize: (data, klass) -> new (List.of(klass))(klass.deserialize(datum) for datum in data)
    serialize: -> this.getValue_()?.serialize() unless this.transient is true
    @withInitial: -> class extends this
      initial: -> new (List.of(this.model.constructor))()

class ReferenceAttribute extends Attribute
  isReference: true
  transient: true
  autoResolve: true

  _initialize: -> this._result = new Varying()

  # a plain request, a function that gives a plain request, or a from() chain which gives one.
  request: null
  result: -> this.result$ ?= this._result.flatten()

  resolveWith: (app) ->
    return if this._resolving is true
    this._resolving = true
    request = if isFunction(this.request) then this.request() else this.request
    return unless request?

    # snoop on the actual model watcher to see if anybody cares, and if so actually
    # run the requestchain and set the result if we get it.
    observation = null
    this.reactTo(this.model.get(this.key).refCount(), (count) =>
      if count is 0 and observation?
        observation.stop()
        observation = null
      else if count > 0 and !observation?
        result =
          if request.all?
            request.all.point(this.model.pointer()).flatMap((request) -> app.resolve(request))
          else if request.isVarying is true
            request.flatMap(app.resolve)
          else
            app.resolve(request)
        return unless result?
        this._result.set(result)
        observation = this.reactTo(result, (x) => types.result.success.match(x, (y) => this.setValue(y)))
    )
    return

  @to: (x) -> class extends this
    request: x


module.exports = {
  Attribute: Attribute

  Text: TextAttribute
  Enum: EnumAttribute
  Number: NumberAttribute
  Boolean: BooleanAttribute
  Date: DateAttribute
  Model: ModelAttribute
  List: ListAttribute
  Reference: ReferenceAttribute
}

