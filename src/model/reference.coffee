Varying = require('../core/varying').Varying
util = require('../util/util')

# A `Resolver` has simply a method called `resolve` which t%3Driggers its
# replacement with whatever it is trying to resolve within its parent
# `Reference`.
#
# The default implementation doesn't do anything useful. See the
# `RequestResolver` and `RequestReference` for the base use case.
class Resolver
  constructor: (@parent, @value, @options = {}) ->
  resolve: -> this.parent.setValue(this.value)

  # delegate model-like things to parent.
  # TODO: similarly dangerous.
  get: ->
  watch: (key) -> this.parent.watch(key)
  watchAll: -> this.parent.watchAll()


# A `Reference` squirrels away the idea of a value that is resolvable but
# should be explicitly resolved (and possibly needs input). It exposes as its
# value the resolver, which when invoked gets replaced with the resolved value.
class Reference extends Varying
  @resolverClass: Resolver
  constructor: (@inner, @flatValue, @options = {}) ->
    super(this._resolver())

  _resolver: -> new this.constructor.resolverClass(this, this.inner, this.options)

  map: (f) ->
    result = new Reference()
    this.reactNow((val) -> result.setValue(f(val)))

    # easier debugging.
    result._parent = this
    result._mapper = f

    result

  # make references transparent to models.
  # TODO: is this dangerous? this seems magical and bad.
  get: ->
  watch: (key) ->
    this.map (val) ->
      if val instanceof require('./model').Model # ugh circular.
        val.watch(key)
      else if val instanceof Resolver
        null
      else
        val
  watchAll: ->
    this.map (val) ->
      if val instanceof require('./model').Model # ugh circular.
        val.watchAll()
      else
        null



# A `Resolver` that resolves `Request`s. It takes the `app` and kicks off the
# request before resolution.
class RequestResolver extends Resolver
  constructor: (@parent, @request, @options = {}) ->
    this.options.map ?= (request) -> request.map((result) -> result.successOrElse(null))
  resolve: (app) ->
    store = app.getStore(this.request)

    if store?
      store.handle()
      this.parent.setValue(this.options.map(this.request))
    else
      this.parent.setValue(null)

class RequestReference extends Reference
  @resolverClass: RequestResolver


# A `ModelResolver` gives in the context of the model an attribute is a part
# of. This becomes useful for example when deserializing, where you don't have
# context on what the eventual model is that you're interacting with.
class ModelResolver extends Resolver
  constructor: (@parent, @map, @options = {}) ->
  resolve: (model) ->
    this.parent.setValue(this.map(model))

class ModelReference extends Reference
  @resolverClass: ModelResolver



util.extend(module.exports,
  Reference: Reference
  RequestReference: RequestReference
  ModelReference: ModelReference

  Resolver: Resolver
  RequestResolver: RequestResolver
  ModelResolver: ModelResolver
)

