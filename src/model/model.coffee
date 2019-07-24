# **Model**s contain primarily an attribute bag, a schema for said bag, and
# eventing around modifications to it.

cases = require('../core/types').from
{ match, otherwise } = require('../core/case')
types = require('../core/types')

{ Map, Nothing } = require('../collection/map')
{ Varying } = require('../core/varying')
{ deepGet, deepSet, isFunction, isString } = require('../util/util')


class Model extends Map
  isModel: true

  # We take in a data bag and optionally some options for this Model.
  # Options are for both framework and implementation use.
  constructor: (data = {}, options) ->
    this._attributes = {}
    super(data, options)
    this._bind() # kick off bindings only after basic init.

  # we override here to make one small optimization: if the requested key is
  # bound, we just return the binding that we already necessarily have anyway
  # rather than make it all go through an extra layer.
  get: (key) ->
    if this._bindings? and (binding = this._bindings[key])?
      varying = binding.parent
      varying.__owner ?= this # TODO: again, still don't like this #145
      varying
    else
      super(key)

  # Get an data about this model. Differs from Map#get only in that it looks at
  # attributes for initial values (and potentially writes them).
  # TODO: a lot of copypasta from Map, but we have a different flowpath because
  # attributes may decline shadowing.
  get_: (key) ->
    value = deepGet(this.data, key)

    # we will need this if we have a nothingish value:
    attribute = this.attribute(key) if !value? or (value is Nothing)

    # first, if we have literally null we check for shadowing.
    if !value? and this._parent?
      value = this._parent.get_(key)

      if value?.isEnumerable is true and (attribute?.shadow isnt false)
        # shadow the result, but only if we are supposed to.
        value = value.shadow()
        this.set(key, value)

    # now that we have avoided shadowing logic, clear Nothing:
    value = null if value is Nothing

    # and if we still have no value, we want to look at attribute initials
    if !value? and attribute?
      value = attribute.initial()
      this.set(key, value) if (attribute.writeInitial is true) and (value isnt undefined)

    value ? null # drop undef to null

  # Get all attribute classes for this model.
  attributes: -> this.attribute(key) for key of this.constructor.schema.attributes

  # Get an attribute class instance for this model by key.
  attribute: (key) -> this._attributes[key] ?=
    new (this.constructor.schema.attributes[key])?(this, key)

  # Actually set up our bindings.
  _bind: ->
    this._bindings = {}
    for key, binding of this.constructor.schema.bindings
      this._bindings[key] = this.reactTo(binding.all.point(this.pointer()), this.set(key))
    return

  pointer: -> this.pointer$ ?= match(
    cases.dynamic (x) =>
      if isFunction(x)
        Varying.of(x(this))
      else if isString(x)
        this.get(x)
      else
        Varying.of(x)
    cases.get (x) => this.get(x)
    cases.subject (x) =>
      if x? then this.get('subject').flatMap((s) -> s?.get(x))
      else this.get('subject')
    cases.attribute (x) => new Varying(this.attribute(x))
    cases.varying (x) => if isFunction(x) then Varying.of(x(this)) else Varying.of(x)
    cases.app (x) =>
      if (app = this.options.app)?
        if x? then app.get(x) else new Varying(app)
      else cases.app()
    cases.self (x) => if isFunction(x) then Varying.of(x(this)) else Varying.of(this)
  )

  # Returns a list of the validation results that have been bound against this model.
  validations: -> this._validations$ ?= do =>
    { List } = require('../collection/list')
    result = new List(this.constructor.schema.validations)
      .flatMap((binding) => binding.all.point(this.pointer()))
    result.destroyWith(this)
    result

  # Returns a list of the currently failing validation results.
  # Unwraps the types.validity.error case class because we know they're errors.
  errors: -> this._errors$ ?= this.validations().filter(types.validity.error.match).map((error) -> error.getError())

  # Returns a `Varying` of `true` or `false` depending on whether this model is
  # valid or not.
  valid: -> this._valid$ ?=
    this.errors().length.map((length) -> length is 0)

  # Handles parent changes; mostly exists in Map but we wrap to additionally
  # bail if the changed parent attribute is a bound value; we want that to
  # update naturally from our own bindings.
  _parentChanged: (key, newValue, oldValue) -> super(key, newValue, oldValue) unless this._bindings[key]?

  __destroy: ->
    super()
    attribute?.destroy() for _, attribute of this._attributes
    this._attributes = null
    return

  # Overridden to define model characteristics like attributes, bindings, and validations.
  # Usually this is done through the Model.build mechanism rather than directly.
  @schema: { attributes: {}, bindings: {}, validations: [] }

  # Takes in a data hash and relies upon attribute definition to provide a sane
  # default deserialization methodology.
  @deserialize: (data) ->
    for key, attribute of this.schema.attributes
      prop = deepGet(data, key)
      deepSet(data, key)(attribute.deserialize(prop)) if prop?

    new this(data)

  # Quick shortcut to define the schema of this model.
  @build: (parts...) ->
    schema = {
      attributes: Object.assign({}, this.schema.attributes),
      bindings: Object.assign({}, this.schema.bindings),
      validations: this.schema.validations.slice()
    }
    part(schema) for part in parts

    class extends this
      @schema: schema


module.exports = { Model }

