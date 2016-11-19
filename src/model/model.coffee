# **Model**s contain primarily an attribute bag, a schema for said bag, and
# eventing around modifications to it.

from = require('../core/from')
{ match, otherwise } = require('../core/case')
types = require('../util/types')

{ Base } = require('../core/base')
{ Varying } = require('../core/varying')
util = require('../util/util')

# sentinel value to record a child-nulled value. instantiate a class instance
# so that it doesn't read as a simple object.
class NullClass
Null = new NullClass()

# Use Base to get basic methods.
class Model extends Base

  # We take in an attribute bag and optionally some options for this Model.
  # Options are for both framework and implementation use.
  #
  constructor: (attributes = {}, @options = {}) ->
    super()

    # Init attribute store so we can bind against it.
    this.attributes = {}

    # Init various caches.
    this._attributes = {}
    this._watches = {}
    this._resolves = {}

    # If we have a designated shadow parent, set it.
    this._parent = this.options.parent

    # Allow setup that happens before attribute binding occurs, without
    # overriding constructor args.
    this._preinitialize?()

    # Drop in our attributes.
    this.set(attributes)

    # Allow setup tasks without overriding+passing along constructor args.
    this._initialize?()

    # Set our binders against those attributes
    this._bind()

  # Get an attribute about this model. The key can be a dot-separated path into
  # a nested plain model. We do not traverse into submodels that have been
  # inflated.
  #
  # If we are a shadow copy, we'll delegate to parent if we find nothing.
  #
  # TODO: bypassAttribute is an ugly hack around an infrecuse.
  #
  # **Returns** the value of the given key.
  get: (key, bypassAttribute = false) ->
    # first try getting self.
    value = util.deepGet(this.attributes, key)

    # otherwise try the shadow parent.
    unless value?
      value = this._parent?.get(key)

      if value instanceof Model
        # if we got a model instance back, we'll want to shadowclone it and
        # write that clone to self. don't worry, if they never touch it again
        # it'll look like nothing happened at all.
        value = this.set(key, value.shadow())

    # collapse shadow-nulled sentinels to null.
    value = if value is Null then null else value

    # if that fails, check the attribute
    if !value? and bypassAttribute is false
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

  # Set an attribute about this model. Takes two forms:
  #
  # 1. Two fixed parameters. As with get, the first parameter is a dot-separated
  #    string key. The second parameter is the value to set.
  # 2. A hash. It can be deeply nested, but submodels aren't dealt with
  #    specially.
  #
  # Does nothing if the given value is no different from the current.
  #
  # **Returns** the value that was set.
  set: (args...) ->
    if args.length is 1 and util.isPlainObject(args[0])
      util.traverse(args[0], (path, value) => this.set(path, value))

    else if args.length is 2 and util.isPlainObject(args[1])
      obj = {}
      util.deepSet(obj, args[0])(args[1])
      this.set(obj)

    else if args.length is 2
      [ key, value ] = args

      oldValue = util.deepGet(this.attributes, key) # TODO: doesn't account for default etc.
      return value if oldValue is value

      util.deepSet(this.attributes, key)(if value is Null then null else value)
      this._emitChange(key, value, oldValue)

      value

  # Clear the value of some attribute. If we are a shadow copy, we'll actually
  # leave behind a sentinel so that we know not to read into our parent.
  #
  # If the value has changed as a result of this operation, a change event will
  # be issued.
  #
  # **Returns** the value that was cleared.
  unset: (key) ->
    if this._parent?
      oldValue = this.get(key)
      util.deepSet(this.attributes, key)(Null)
      this._emitChange(key, this.get(key), oldValue) unless oldValue is null

    else
      oldValue = this.get(key)
      this._deleteAttr(key)

    oldValue

  # Takes an entire attribute bag, and replaces our own attributes with it.
  # Will fire the appropriate events.
  #
  # **Returns** nothing.
  setAll: (attrs) ->
    # first clear off attributes that are about to no longer exist.
    util.traverseAll(this.attributes, (path, value) => this.unset(path.join('.')) unless util.deepGet(attrs, path)?)

    # now add in the ones we now want.
    this.set(attrs)

    null

  # Get a `Varying` object for a particular key. This simply creates a new
  # Varying that points at our attribute.
  #
  # **Returns** a `Varying` object against our attribute at `key`.
  watch: (key) ->
    this._watches[key] ?= do =>
      varying = new Varying(this.get(key))
      this.listenTo(this._parent, "changed:#{key}", => varying.set(this.get(key))) if this._parent?
      this.listenTo(this, "changed:#{key}", (newValue) -> varying.set(newValue))
      varying

  # Like `#watch(key)`, but if the attribute in question is an unresolved
  # `ReferenceAttribute` then we take the given app object and kick off the
  # appropriate actions. The resulting `Varying` from this call contains
  # wrapped `types.result` cases. The actual property key will be populated
  # with a successful value if it comes.
  terminate = (x) -> if x.all? then x.all else x # TODO: becoming a common pattern. move to util.
  resolve: (key, app) ->
    this._resolves[key] ?= do =>
      this.watch(key).flatMap (value) =>
        if !value? and (attribute = this.attribute(key)).isReference is true
          # point the attribute's resolver definition with an app and count
          # on it to fire off the request. but listen to the result and set
          # the concret value if we get one.
          result = terminate(attribute.resolver())
            .point((x) => this.constructor._point(x, this, app))
            .map((x) => x?.mapSuccess((y) -> attribute.constructor.deserialize(y)) ? x)

          result.reactNow((x) => types.result.success.match(x, (y) => this.set(key, y)))
          result
        else
          new Varying(value) # wrap for symmetry (because this is a flatMap)

  # Get a `Varying` object for this entire object. It will emit a change event
  # any time any attribute on the entire object changes. Does not event when
  # nested model attributes change, however.
  #
  # **Returns** a `Varying` object against our whole model.
  watchAll: ->
    varying = new Varying(this)
    this.listenTo(this, 'anyChanged', => varying.set(this, true)) # TODO this is no longer viable

  # Class-level storage bucket for attribute schema definition.
  @attributes: ->
    if this._attributesAgainst isnt this
      this._attributesAgainst = this
      this._attributes = {}

    this._attributes

  # Get all attributes declared on this model, including inherited attributes.
  # TODO: confusing naming scheme probably
  @allAttributes: ->
    attrs = {}

    recurse = (obj) =>
      return unless obj.attributes?
      recurse(util.superClass(obj)) if util.superClass(obj)?
      attrs[key] = attr for key, attr of obj.attributes()
      null

    recurse(this)
    attrs

  # Declare an attribute for this model.
  @attribute: (key, attribute) -> this.attributes()[key] = attribute

  # Get an attribute for this model.
  #
  # **Returns** an `Attribute` object wrapping an attribute for the attribute
  # at the given key.
  attribute: (key) ->
    recurse = (obj) =>
      return unless obj.attributes?
      result = new (obj.attributes()[key])?(this, key)

      if result?
        result
      else if util.superClass(obj)?
        recurse(util.superClass(obj))

    key = key.join('.') if util.isArray(key)
    this._attributes[key] ?= recurse(this.constructor)

  # Get an attribute class for this model.
  #
  # **Returns** an `Attribute` class object for the attribute at the given key.
  attributeClass: (key) -> this.constructor.attributes()[key]

  # Returns actual instances of every attribute associated with this model.
  #
  # **Returns** an array of `Attribute`s.
  allAttributes: -> this.attribute(key) for key of this.constructor.allAttributes()

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
  terminate = (x) -> if x.all? then x.all else x
  _bind: ->
    this._binders = {}
    recurse = (obj) =>
      for binder in obj.binders() when !this._binders[binder._key]?
        do (binder) =>
          key = binder._key
          this._binders[key] = terminate(binder)
            .point((x) => this.constructor._point(x, this))
            .reactNow((value) => this.set(key, value))

      superClass = util.superClass(obj)
      recurse(superClass) if superClass and superClass.binders?
      null

    recurse(this.constructor)
    null

  @_point: match(
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
    from.default.app (_, self, app) -> if app? then new Varying(app) else from.default.app()
    from.default.self (x, self) -> if util.isFunction(x) then Varying.ly(x(self)) else Varying.ly(self)
  )

  # Revert a particular attribute on this model. After this, the model will
  # return whatever its parent thinks the attribute should be. If no parent
  # exists, this function will fail silently. The key can be a dot-separated
  # path.
  #
  # If the value has changed as a result of this operation, a change event will
  # be issued.
  #
  # **Returns** the value that was cleared.
  revert: (key) ->
    return unless this._parent?
    this._deleteAttr(key)

  # Shadow-copies a model. This allows a second copy of the model to function
  # as its own model instance and keep a separate set of changes, but which
  # will fall back on the original model if asked about an attribute it doesn't
  # know about.
  #
  # **Returns** a new shadow copy, which is an instance of `Model`.
  shadow: (klass) -> new (klass ? this.constructor)({}, util.extendNew(this.options, { parent: this }))

  # Checks if we've changed relative to our original.
  #
  # **Returns** true if we have been modified.
  modified: (deep = true) ->
    return false unless this._parent?

    result = false
    util.traverse(this.attributes, (path) => result = true if this.attrModified(path, deep))
    result

  # Checks if one attribute has change relative to our original.
  #
  # **Returns** true if the attribute has been modified
  attrModified: (path, deep) ->
    return false unless this._parent?

    value = util.deepGet(this.attributes, path)
    return false if !value? # necessarily we're just falling through

    value = null if value is Null

    isDeep =
      if !deep?
        true
      else if util.isFunction(deep)
        deep(this, path, value)
      else
        deep is true

    attribute = this.attribute(path)
    transient = attribute? and attribute.transient is true

    if !transient
      parentValue = this._parent.get(path)

      if value instanceof Model
        # Check that parentValue != value
        # If it isn't, check value children.
        !(parentValue in value.originals()) or (isDeep is true and value.modified(deep))
      else
        parentValue isnt value and !(!parentValue? and !value?)
    else
      false

  # Watches whether we've changed relative to our original.
  #
  # **Returns** Varying[Boolean] indicating modified state.
  watchModified: (deep) ->
    isDeep =
      if !deep?
        true
      else if util.isFunction(deep)
        deep(this)
      else
        deep is true

    if isDeep is true
      # for deep, we have to listen not only to our own state changes, but also
      # to any models we might contain.
      this._watchModifiedDeep$ ?= do =>
        # return if we're already initializing. This is to prevent infinite
        # recursion; if we don't already have a fully realized watch but we've
        # started one, this instance's state is already covered.
        return if this._watchModifiedDeep$init is true
        this._watchModifiedDeep$init = true

        result = new Varying(this.modified(deep))
        this.on 'anyChanged', (path) =>
          if this.attrModified(path, deep)
            result.set(true)
          else
            result.set(this.modified(deep))

        watchModel = (model) =>
          model.watchModified(deep).react (isChanged) =>
            if isChanged is true
              result.set(true)
            else
              result.set(this.modified(deep))

        # wait for varying to resolve into a model, then stop watching it.
        watchVarying = (varying) =>
          resolveVarying = (model) =>
            if model instanceof Model
              this._subvaryings().remove(varying)
              this._submodels().add(model)
              varying.off('changed', resolveVarying) # stop reacting.
          varying.react resolveVarying

        uniqSubmodels = this._submodels().uniq()
        uniqSubvaryings = this._subvaryings().uniq()
        watchModel(model) for model in uniqSubmodels.list
        watchVarying(varying) for varying in uniqSubvaryings.list
        uniqSubmodels.on('added', (newModel) => watchModel(newModel))
        uniqSubmodels.on('removed', (oldModel) => this.unlistenTo(oldModel.watchModified(deep)))
        uniqSubvaryings.on('added', (newVarying) => watchVarying(newVarying))

        result

    else
      # for shallow, we only care about refs, which we'll reliably get events
      # for via our own change event.
      this._watchModified$ ?= do =>
        result = new Varying(this.modified(deep))
        this.on 'anyChanged', (path) =>
          if this.attrModified(path, deep)
            result.set(true)
          else
            result.set(this.modified(deep))

        result

  # Returns the original copy of a model. Returns itself if it's already an
  # original model.
  #
  # **Returns** an instance of `Model`.
  original: -> this._parent?.original() ? this

  # Returns all shadow parents of a model. Returns an empty array if it's
  # already an original model.
  #
  # **Returns** Array[Model] of shadow parents.
  originals: ->
    cur = this
    (cur = cur._parent) while cur._parent?

  # Merges the current model's changed attributes into its parent's. Fails
  # silently if it has no parent.
  #
  # TODO: should be optionally deep.
  #
  # **Returns** nothing.
  merge: -> this._parent?.set(this.attributes); null

  # Returns a `List` of issues with this model. If no issues exist, the `List`
  # will be empty.
  #
  # **Returns** `List[Issue]`
  issues: ->
    this.issues$ ?= do =>
      issueList = (attr.issues() for attr in this.allAttributes() when attr.issues?)
      issueList.unshift(this._issues()) if this._issues?
      (new (require('../collection/collection').CattedList)(issueList)).filter((issue) -> issue.active)

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

  # TODO: I'm not really sure if this is best here.
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

  # TODO: Also not totally sure this is best here.
  # Returns a serialized representation of the given model.
  #
  # **Returns** a serialization-ready plain object with all the relevant
  # attributes within it.
  @serialize: (model, opts = {}) ->
    walkAttrs = (keys, src, target) =>
      for subKey, value of src
        thisKey = keys.concat([ subKey ])
        strKey = thisKey.join('.')

        attribute = model.attribute(strKey)

        result =
          if value is Null
            undefined
          else if attribute? and attribute.serialize?
            attribute.serialize(opts)
          else if util.isPlainObject(value)
            innerResult = target[subKey] ? {}
            walkAttrs(thisKey, value, innerResult)
            innerResult
          else
            value

        target[subKey] = result

      target

    result =
      if model._parent?
        Model.serialize(model._parent, opts)
      else
        {}
    walkAttrs([], model.attributes, result)
    result

  # Shortcut method to serialize a model by the default rules specified by
  # its own constructor.
  serialize: -> this.constructor.serialize(this)

  # Helper used by `revert()` and some paths of `unset()` to actually clear out
  # a particular key.
  _deleteAttr: (key) ->
    oldValue = util.deepDelete(this.attributes, key)
    newValue = this.get(key)
    this._emitChange(key, newValue, oldValue) unless newValue is oldValue

    oldValue

  # Helper to generate change events. We emit events for both the actual changed
  # key along with all its parent nests, which this deals with.
  _emitChange: (key, newValue, oldValue) ->
    # split out our path parts if necessary.
    parts = if util.isArray(key) then key else key.split('.')

    # track all our submodels.
    this._submodels().remove(oldValue) if oldValue instanceof Model
    this._submodels().add(newValue) if newValue instanceof Model

    # track all our subvaryings.
    this._subvaryings().remove(oldValue) if oldValue instanceof Varying
    this._subvaryings().add(newValue) if newValue instanceof Varying

    # emit helper.
    emit = (name, partKey) => this.emit("#{name}:#{partKey}", newValue, oldValue, partKey)

    # emit on the direct path part.
    emit('changed', parts.join('.'))

    # emit on the path parents.
    while parts.length > 1
      parts.pop()
      emit('subKeyChanged', parts.join('.'))

    # emit that something changed at all.
    this.emit('anyChanged', key, newValue, oldValue) # TODO: why doesn't simply leaving off the namespace work?

    null

  # Returns the submodel and subvarying list for this class. Instantiates lazily when
  # requested otherwise we get stack overflow.
  _submodels: -> this._submodels$ ?= new (require('../collection/list').List)()
  _subvaryings: -> this._subvaryings$ ?= new (require('../collection/list').List)()


# Export.
util.extend(module.exports,
  Model: Model
)

