from = require('../core/from')
types = require('../util/types')
{ Model } = require('./model')
{ Map } = require('../collection/map')
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
  serialize: -> this.constructor.modelClass.prototype.serialize.call(this.getValue()) unless this.transient is true

  @of: (modelClass) -> class extends this
    @modelClass: modelClass

class ListAttribute extends Attribute
  @listClass: List

  writeDefault: true

  @deserialize: (data) -> this.listClass.deserialize(data)
  serialize: -> this.constructor.listClass.prototype.serialize.call(this.getValue()) unless this.transient is true

  @of: (listClass) -> class extends this
    @listClass: listClass

class ReferenceAttribute extends Attribute
  isReference: true
  transient: true
  autoResolve: true

  # either a plain request or a from() chain which gives one.
  request: null

  resolveWith: (app) ->
    return if this._resolving is true
    this._resolving = true
    return unless (request = this.request)?

    # snoop on the actual model watcher to see if anybody cares, and if so actually
    # run the requestchain and set the result if we get it.
    # TODO: or should we just do it right away, if someone is .get()ing?
    observation = null
    this.reactTo(this.model.watch(this.key).refCount(), (count) =>
      if count is 0 and observation?
        observation.stop()
        observation = null
      else if count > 0 and !observation?
        result =
          if request.all?
            request.all.point(this.model.pointer()).flatMap((request) -> app.resolve(request))
          else
            app.resolve(request)
        return unless result?
        observation = this.reactTo(result, (x) => types.result.success.match(x, (y) => this.setValue(y)))
    )

    null

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

