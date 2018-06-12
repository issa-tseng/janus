# **Model**s contain primarily an attribute bag, a schema for said bag, and
# eventing around modifications to it.

from = require('../core/from')
{ match, otherwise } = require('../core/case')
types = require('../util/types')

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

  # Get an data about this model. The key can be a dot-separated path into
  # a nested plain model. We do not traverse into submodels.
  #
  # If we are a shadow copy, we'll delegate to parent if we find nothing.
  #
  # **Returns** the value of the given key.
  get: (key) ->
    # see what Map says; it handles basic attrs and shadowing.
    value = super(key)

    # if that fails, check the attribute.
    if !value? and (attribute = this.attribute(key))?
      value =
        if attribute.writeDefault is true
          # first, check forceDefault, and set-on-write if present.
          this.set(key, attribute.default())
        else
          # failing that, call default in general.
          attribute.default()

    # drop undef to null
    value ?= null

  # Like `#watch(key)`, but if the attribute in question is an unresolved
  # `ReferenceAttribute` then we take the given app object and kick off the
  # appropriate actions. The resulting `Varying` from this call contains
  # wrapped `types.result` cases. The actual property key will be populated
  # with a successful value if it comes.
  resolve: (key, app) ->
    if !this.get(key)? and (attribute = this.attribute(key))?.isReference is true
      result = new Varying(attribute.resolver().all
        .point((x) => this.constructor.point(x, this, app))
        .map((x) => x?.mapSuccess((y) -> attribute.constructor.deserialize(y)) ? x)
      ).flatten()

      # snoop on the result if someone else reacts on it, and set successful
      # values to the attribute.
      varied = null
      result.refCount().reactLater((count) =>
        if count is 1
          if varied?
            varied.stop()
            varied = null
          else
            varied = result.react((x) => types.result.success.match(x, (y) => this.set(key, y)))
      )

      result
    else
      this.watch(key)

  # Like `#resolve(key, app)`, but calls react on the resulting request on
  # your behalf.
  # TODO: can we push this to the bottom of the stack without a timeout? is
  # it inviting trouble if we introduce reaction priority, or a concept of
  # a cleanup/finally reaction?
  # or perhaps in addition to #stop we have a #wrapup that allows queued reactions
  # to complete first.
  resolveNow: (key, app) -> this.resolve(key, app).react((x) -> setTimeout((=> this.stop()), 0) if types.result.complete.match(x))

  # Get an attribute for this model.
  #
  # **Returns** an `Attribute` object wrapping an attribute for the attribute
  # at the given key.
  attribute: (key) -> this._attributes[key] ?=
    new (this.constructor.schema.attributes[key])?(this, key)

  # Actually set up our binding.
  # **Returns** nothing.
  _bind: ->
    this._bindings = {}
    for key, binding of this.constructor.schema.bindings
      this._bindings[key] = binding.all
        .point(this.pointer())
        .react(this.set(key))
    null

  @point: match(
    from.default.dynamic (x, self) ->
      if util.isFunction(x)
        Varying.ly(x(self))
      else if util.isString(x)
        self.watch(x)
      else
        Varying.ly(x) # i guess? TODO
    from.default.watch (x, self) -> self.watch(x)
    from.default.resolve (x, self, app) -> if app? then self.resolve(x, app) else from.default.resolve(x)
    from.default.attribute (x, self) -> new Varying(self.attribute(x))
    from.default.varying (x, self) -> if util.isFunction(x) then Varying.ly(x(self)) else Varying.ly(x)
    from.default.app (x, self, app) ->
      app ?= self.options.app
      if app?
        if x? then app.resolve(x) else new Varying(app)
      else from.default.app()
    from.default.self (x, self) -> if util.isFunction(x) then Varying.ly(x(self)) else Varying.ly(self)
  )

  pointer: -> (x) => this.constructor.point(x, this)

  # Returns a list of the issue results that have been bound against this model.
  issues: -> this._issues$ ?= do =>
    { List } = require('../collection/list')
    new List(this.constructor.schema.issues.map((binding) => binding.all.point(this.pointer())))

  # Returns a `Varying` of `true` or `false` depending on whether this model is
  # valid or not.
  #
  # **Returns** `Varying[Boolean]` indicating current validity.
  valid: -> this._valid$ ?=
    this.issues()
      .filter((issue) -> issue.map(types.validity.invalid.match))
      .watchLength().map((length) -> length is 0)

  # Overridden to define model characteristics like attributes, bindings, and issues.
  # Usually this is done through the Model.build mechanism rather than directly.
  @schema: { attributes: {}, bindings: {}, issues: [] }

  # Takes in a data hash and relies upon attribute definition to provide a sane
  # default deserialization methodology.
  #
  # **Returns** a `Model` or subclass of `Model`, depending on invocation, with
  # the data populated.
  @deserialize: (data) ->
    for key, attribute of this.schema.attributes
      prop = util.deepGet(data, key)
      util.deepSet(data, key)(attribute.deserialize(prop)) if prop?

    new this(data)

  # Handles parent changes; mostly exists in Map but we wrap to additionally
  # bail if the changed parent attribute is a bound value; we want that to
  # update naturally from our own bindings.
  _parentChanged: (key, newValue, oldValue) -> super(key, newValue, oldValue) unless this._bindings[key]?

  # Quick shortcut to define the schema of this model.
  @build: (parts...) ->
    schema = {
      attributes: util.extendNew({}, this.schema.attributes),
      bindings: util.extendNew({}, this.schema.bindings),
      issues: this.schema.issues.slice()
    }
    part(schema) for part in parts

    class extends this
      @schema: schema


module.exports = { Model }

