# **Model**s contain primarily an attribute bag, a schema for said bag, and
# eventing around modifications to it.

cases = require('../core/types').from
{ match, otherwise } = require('../core/case')
types = require('../core/types')

{ Null, Map } = require('../collection/map')
{ Varying } = require('../core/varying')
util = require('../util/util')


class Model extends Map
  isModel: true

  # We take in a data bag and optionally some options for this Model.
  # Options are for both framework and implementation use.
  constructor: (data = {}, options) ->
    this._attributes = {}
    super(data, options)
    this._bind() # kick off bindings only after basic init.

  # Get an data about this model. Differs from Map#get only in that it looks at
  # attributes for default values (and potentially writes them).
  get: (key) ->
    value = super(key) # see what Map says; it handles basic attrs and shadowing.

    # if that fails, check the attribute and write if requested.
    if !value? and (attribute = this.attribute(key))?
      value =
        if attribute.writeDefault is true
          this.set(key, attribute.default())
        else
          attribute.default()

    value ? null # drop undef to null

  # Get an attribute class instance for this model by key.
  attribute: (key) -> this._attributes[key] ?=
    new (this.constructor.schema.attributes[key])?(this, key)

  # resolves all resolveable attributes with the given app.
  autoResolveWith: (app) ->
    for key of this.constructor.schema.attributes
      attribute = this.attribute(key)
      attribute.resolveWith(app) if attribute.isReference is attribute.autoResolve is true
    return

  # Actually set up our bindings.
  _bind: ->
    this._bindings = {}
    for key, binding of this.constructor.schema.bindings
      this._bindings[key] = this.reactTo(binding.all.point(this.pointer()), this.set(key))
    return

  pointer: -> this.pointer$ ?= match(
    cases.dynamic (x) =>
      if util.isFunction(x)
        Varying.of(x(this))
      else if util.isString(x)
        this.watch(x)
      else
        Varying.of(x)
    cases.watch (x) => this.watch(x)
    cases.attribute (x) => new Varying(this.attribute(x))
    cases.varying (x) => if util.isFunction(x) then Varying.of(x(this)) else Varying.of(x)
    cases.app (x) =>
      if (app = this.options.app)?
        if x? then app.watch(x) else new Varying(app)
      else cases.app()
    cases.self (x) => if util.isFunction(x) then Varying.of(x(this)) else Varying.of(this)
  )

  # Returns a list of the validation results that have been bound against this model.
  validations: -> this._validations$ ?= do =>
    { List } = require('../collection/list')
    result = new List(this.constructor.schema.validations)
      .flatMap((binding) => binding.all.point(this.pointer()))
    result.destroyWith(this)
    result

  # Returns a list of the currently failing validation results.
  issues: -> this._issues$ ?= this.validations().filter(types.validity.invalid.match)

  # Returns a `Varying` of `true` or `false` depending on whether this model is
  # valid or not.
  valid: -> this._valid$ ?=
    this.issues().watchLength().map((length) -> length is 0)

  # Handles parent changes; mostly exists in Map but we wrap to additionally
  # bail if the changed parent attribute is a bound value; we want that to
  # update naturally from our own bindings.
  _parentChanged: (key, newValue, oldValue) -> super(key, newValue, oldValue) unless this._bindings[key]?

  __destroy: ->
    attribute?.destroy() for _, attribute of this._attributes
    return

  # Overridden to define model characteristics like attributes, bindings, and validations.
  # Usually this is done through the Model.build mechanism rather than directly.
  @schema: { attributes: {}, bindings: {}, validations: [] }

  # Takes in a data hash and relies upon attribute definition to provide a sane
  # default deserialization methodology.
  @deserialize: (data) ->
    for key, attribute of this.schema.attributes
      prop = util.deepGet(data, key)
      util.deepSet(data, key)(attribute.deserialize(prop)) if prop?

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

