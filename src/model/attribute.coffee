
util = require('../util/util')
Model = require('../core/base')

# This derivation theoretically means that `Attributes` can contain schemas,
# which means they can in turn produce `Attributes`. The universe-ending
# implications of this design quirk are left as an exercise to the implementeur.
class Attribute extends Model
  constructor: (@model, @key) ->
    this._initialize?()

  set: (value) -> this.model.set(this.key, value)
  get: -> this.model.get(this.key)

  monitorValue: -> this.model.monitor(this.key)

class TextAttribute extends Attribute

class EnumAttribute extends Attribute
  options: -> []

class NumberAttribute extends Attribute

class DateAttribute extends Attribute

class ModelAttribute extends Attribute


util.extend(module.exports,
  Attribute: Attribute

  TextAttribute: TextAttribute
  EnumAttribute: EnumAttribute
  NumberAttribute: NumberAttribute
  DateAttribute: DateAttribute
  ModelAttribute: ModelAttribute
)

