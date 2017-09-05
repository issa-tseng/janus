# **Model**s contain primarily an attribute bag, a schema for said bag, and
# eventing around modifications to it.

from = require('../core/from')
{ match, otherwise } = require('../core/case')
types = require('../util/types')

{ Null, Struct } = require('../collection/struct')
{ Varying } = require('../core/varying')
util = require('../util/util')


# util:
terminate = (x) -> if x.all? then x.all else x # TODO: becoming a common pattern. move to util.

class Model extends Struct
  isModel: true

  # We take in an attribute bag and optionally some options for this Model.
  # Options are for both framework and implementation use.
  constructor: (attributes = {}, options) ->
    this._attributes = {}
    super(attributes, options)
    this._bind() # kick off bindings only after basic init.

  # Get an attribute about this model. The key can be a dot-separated path into
  # a nested plain model. We do not traverse into submodels.
  #
  # If we are a shadow copy, we'll delegate to parent if we find nothing.
  #
  # **Returns** the value of the given key.
  get: (key) ->
    # see what Struct says; it handles basic attrs and shadowing.
    value = super(key)

    # if that fails, check the attribute.
    if !value?
      attribute = this.attribute(key)
      value =
        if attribute?
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
      result = new Varying(terminate(attribute.resolver())
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

  # Class-level storage bucket for attribute schema definition.
  @attributes: ->
    if @_attributesAgainst isnt this
      @_attributesAgainst = this

      superClass = util.superClass(this)
      @_attributes =
        if superClass.attributes?
          superClass.attributes().shadow()
        else
          new Struct()
    else
      @_attributes

  # Get all attributes declared on this model, including inherited attributes.
  # TODO: should be an easier way to extract this structure.
  @allAttributes: ->
    attrs = @attributes()
    result = {}
    (result[attr] = attrs.get(attr)) for attr in attrs.enumerate()
    result

  # Declare an attribute for this model.
  @attribute: (key, attribute) -> @attributes().set(key,  attribute)

  # Declare an attribute by means of just a default value and an optional class reference.
  @default: (key, value, klass) ->
    klass ?= require('./attribute').Attribute
    wrapped = if util.isFunction(value) then value else (-> value)
    @attribute(key, class extends klass
      default: wrapped
    )

  # Shortcut to declare an attribute that marks an attribute as transient.
  @transient: (key) -> @attributes().set(key, class extends (require('./attribute').Attribute)
    transient: true
  )

  # Get an attribute for this model.
  #
  # **Returns** an `Attribute` object wrapping an attribute for the attribute
  # at the given key.
  attribute: (key) -> this._attributes[key] ?= new (@constructor.attributes().get(key))?(this, key)

  # Returns actual instances of every attribute associated with this model.
  #
  # **Returns** an array of `Attribute`s.
  allAttributes: -> this.attribute(key) for key of @constructor.allAttributes()

  # Store our binders
  @binders: ->
    if this._bindersAgainst isnt this
      this._bindersAgainst = this
      this._binders = []

    this._binders

  # Declare a binding for this model.
  @bind: (key, binding) ->
    binding._key = key # avoids creating new objs; perf.
    this.binders().push(binding)

  # Actually set up our binding.
  # **Returns** nothing.
  _bind: ->
    this._binders = {}
    recurse = (obj) =>
      for binder in obj.binders() when !this._binders[binder._key]?
        do (binder) =>
          key = binder._key
          this._binders[key] = terminate(binder)
            .point((x) => this.constructor.point(x, this))
            .react((value) => this.set(key, value))

      superClass = util.superClass(obj)
      recurse(superClass) if superClass and superClass.binders?
      null

    recurse(this.constructor)
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

  # Returns a `List` of issues with this model. If no issues exist, the `List`
  # will be empty.
  #
  # **Returns** `List[Issue]`
  issues: ->
    this.issues$ ?= do =>
      issueList = (attr.issues() for attr in this.allAttributes() when attr.issues?)
      issueList.unshift(this._issues()) if this._issues?
      (new (require('../collection/derived/catted-list').CattedList)(issueList)).filter((issue) -> issue.active)

  # To specify model-level validation for this model, declare a `_issues()`
  # method:
  #
  # _issues: ->

  # Returns a `Varying` of `true` or `false` depending on whether this model is
  # valid or not. Can be given a `severity` to filter by some threshold.
  #
  # **Returns** `Varying[Boolean]` indicating current validity.
  valid: (severity = 0) ->
    this.issues()
      .filter((issue) -> issue.severity.map((issueSev) -> issueSev <= severity))
      .watchLength()
        .map((length) -> length is 0)

  # Takes in a data hash and relies upon attribute definition to provide a sane
  # default deserialization methodology.
  #
  # **Returns** a `Model` or subclass of `Model`, depending on invocation, with
  # the data populated.
  @deserialize: (data) ->
    for key, attribute of this.allAttributes()
      prop = util.deepGet(data, key)
      util.deepSet(data, key)(attribute.deserialize(prop)) if prop?

    new this(data)

  # Handles parent changes; mostly exists in Struct but we wrap to additionally
  # bail if the changed parent attribute is a bound value; we want that to
  # update naturally from our own bindings.
  _parentChanged: (key, newValue, oldValue) -> super(key, newValue, oldValue) unless this._binders[key]?


module.exports = { Model }

