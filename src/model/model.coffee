# **Model**s contain primarily an attribute bag, a schema for said bag, and
# eventing around modifications to it.

Base = require('../core/base').Base
Varying = require('../core/varying').Varying
{ Reference, Resolver } = require('./reference')
util = require('../util/util')

Binder = require('./binder').Binder

Null = {} # sentinel value to record a child-nulled value

# Use Base to get basic methods.
class Model extends Base

  # We take in an attribute bag and optionally some options for this Model.
  # Options are for both framework and implementation use.
  #
  constructor: (attributes = {}, @options = {}) ->
    super()

    # Init attribute store so we can bind against it.
    this.attributes = {}

    # Init attribute obj cache.
    this._attributes = {}

    # Init watches cache.
    this._watches = {}

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
  # **Returns** the value of the given key.
  get: (key) ->
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

    # if that fails, check the attribute
    unless value?
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

    # collapse shadow-nulled sentinels to null.
    if value is Null then null else value

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

    else if args.length is 2
      [ key, value ] = args

      oldValue = util.deepGet(this.attributes, key) # TODO: doesn't account for default etc.
      return value if oldValue is value

      util.deepSet(this.attributes, key)(if value is Null then null else value)

      this._emitChange(key, value, oldValue)
      this.validate(key)

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
      this._emitChange(key, null, oldValue) unless oldValue is null

    else
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
      varying.listenTo(this._parent, "changed:#{key}", -> varying.setValue(this.get(key))) if this._parent?
      varying.listenTo(this, "changed:#{key}", (newValue) -> varying.setValue(newValue))

  # Get a `Varying` object for this entire object. It will emit a change event
  # any time any attribute on the entire object changes. Does not event when
  # nested model attributes change, however.
  #
  # **Returns** a `Varying` object against our whole model.
  watchAll: ->
    varying = new Varying(this)
    varying.listenTo(this, 'anyChanged', => varying.setValue(this, true))

  # Class-level storage bucket for attribute schema definition.
  @attributes: -> this._attributes ?= {}

  # Declare an attribute for this model.
  @attribute: (key, attribute) -> this.attributes()[key] = attribute

  # Get an attribute for this model.
  #
  # **Returns** an `Attribute` object wrapping an attribute for the attribute
  # at the given key.
  attribute: (key) -> this._attributes[key] ?= new (this.constructor.attributes()[key])?(this, key)

  # Get an attribute class for this model.
  #
  # **Returns** an `Attribute` class object for the attribute at the given key.
  attributeClass: (key) -> this.constructor.attributes()[key]

  # Store our binders
  @binders: ->
    if this._bindersAgainst isnt this
      this._bindersAgainst = this
      this._binders = []

    this._binders

  # Declare a binding for this model.
  @bind: (key) ->
    binder = new Binder(key)
    this.binders().push(binder)
    binder

  # Actually set up our binding.
  # **Returns** nothing.
  _bind: ->
    this._binders = {}
    recurse = (obj) =>
      (this._binders[binder._key] = binder.bind(this)) for binder in obj.binders() when !this._binders[binder._key]?
      recurse(obj.__super__.constructor) if obj.__super__? and obj.__super__.constructor.binders?
      null

    debugger
    recurse(this.constructor)
    null

  # Trip a binder to rebind.
  rebind: (key) ->
    this._binders[key]?.apply()

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
  shadow: -> new this.constructor({}, util.extendNew(this.options, { parent: this }))

  # Checks if we've changed relative to our original.
  #
  # **Returns** true if we have been modified.
  modified: (deep = true) ->
    return false unless this._parent?

    result = false
    util.traverse this.attributes, (path, value) =>
      attribute = this.attribute(path)
      unless !attribute? or attribute.transient is true
        parentValue = this._parent.get(path)
        if value instanceof Model
          if deep is true
            result = result or value.modified()
          else
            result = result or parentValue isnt value._parent
        else
          value = null if value is Null
          result = true if parentValue isnt value

    result

  # Returns the original copy of a model. Returns itself if it's already an
  # original model.
  #
  # **Returns** an instance of `Model`.
  original: -> this._parent? ? this

  # Merges the current model's changed attributes into its parent's. Fails
  # silently if it has no parent.
  #
  # TODO: should be [optionally?] deep.
  #
  # **Returns** nothing.
  merge: -> this._parent?.set(this.attributes); null

  # Performs validation of one or all attributes. Returns a `ValidationResult`
  # of either `Valid` or `Error`, the latter of which contains details about
  # the infractions.
  #
  # **Returns** a `ValidationResult`.
  validate: (key) ->
    # TODO: implement

  # TODO: I'm not really sure if this is best here.
  # Takes in a data hash and relies upon attribute definition to provide a sane
  # default deserialization methodology.
  #
  # **Returns** a `Model` or subclass of `Model`, depending on invocation, with
  # the data populated.
  @deserialize: (data) ->
    for key, attribute of this.attributes()
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
            result = {}
            walkAttrs(thisKey, value, result)
            result if util.hasProperties(result)
          else
            value

        result = result.flatValue if result instanceof Reference
        target[subKey] = result

      target

    result =
      if model._parent?
        Model.serialize(model._parent, opts)
      else
        {}
    walkAttrs([], model.attributes, result)
    result

  # TODO: do we want this?
  serialize: -> this.constructor.serialize(this)

  # Helper used by `revert()` and some paths of `unset()` to actually clear out
  # a particular key.
  _deleteAttr: (key) ->
    util.deepSet(this.attributes, key) (obj, subkey) =>
      return unless obj?

      oldValue = obj[subkey]
      delete obj[subkey]

      newValue = this.get(key)
      this._emitChange(key, newValue, oldValue) unless newValue is oldValue

      oldValue

  # Helper to generate change events. We emit events for both the actual changed
  # key along with all its parent nests, which this deals with.
  _emitChange: (key, newValue, oldValue) ->
    parts =
      if util.isArray(key)
        key
      else
        key.split('.')

    emit = (name, partKey) => this.emit("#{name}:#{partKey}", newValue, oldValue, partKey)

    emit('changed', parts.join('.'))

    while parts.length > 1
      parts.pop()
      emit('subKeyChanged', parts.join('.'))

    this.emit('anyChanged') # TODO: why doesn't simply leaving off the namespace work?

    null


# Export.
util.extend(module.exports,
  Model: Model
)

