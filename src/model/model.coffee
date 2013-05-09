# **Model**s contain primarily an attribute bag, a schema for said bag, and
# eventing around modifications to it.

Base = require('../core/base').Base
util = require('../util/util')

Null = {} # sentinel value to record a child-nulled value

# Use Base to get basic methods.
class Model extends Base

  # We take in an attribute bag and optionally some options for this Model.
  # Options are for both framework and implementation use; the options the
  # framework cares about are:
  # - `validateOnCreate`: Determines whether to validate the attributes given
  #   with the constructor. Defaults to **true**.
  constructor: (@attributes = {}, @options = {}) ->
    super()

    # We've swallowed the provided attributes whole; do we want to validate
    # them before proceeding?
    this.validate() unless this.options.validateOnCreate is false

  # Override me in implementations to express expected attribute types and
  # validation methods.
  schema: {}

  # Get an attribute about this model. The key can be a dot-separated path into
  # a nested plain model. We do not traverse into submodels that have been
  # inflated.
  #
  # If we are a shadow copy, we'll delegate to parent if we find nothing.
  #
  # **Returns** the value of the given key.
  get: (key) ->
    value =
      util.deepGet(this.attributes, key) ?
      this._parent?.get(key) ?
      null

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
      oldValue = util.deepGet(this.attributes, key) 
      return value if oldValue is value

      util.deepSet(this.attributes, key)(if value is Null then null else value)

      this.emit("change:#{key}", value, oldValue)
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
    oldValue = this.get(key)

    if this._parent?
      util.deepSet(this.attributes, key)(Null)
    else
      this._deleteAttr(key)

    this.emit("change:#{key}", null, oldValue) if oldValue isnt null

    oldValue

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
  shadow: ->
    shadow = new this.constructor({}, this.options)
    shadow._parent = this
    shadow

  # Returns the original copy of a model. Returns itself if it's already an
  # original model.
  #
  # **Returns** an instance of `Model`.
  original: -> this._parent? ? this

  # Merges the current model's changed attributes into its parent's. Fails
  # silently if it has no parent.
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

  # Helper used by `revert()` and some paths of `unset()` to actually clear out
  # a particular key.
  _deleteAttr: (key) ->
    util.deepSet(this.attributes, key) (obj, subkey) =>
      oldValue = obj[subkey]
      delete obj[subkey]

      newValue = this.get(key)
      this.emit("change:#{key}", newValue, oldValue) if newValue isnt oldValue

      oldValue

# Export.
util.extend(module.exports,
  Model: Model
)

