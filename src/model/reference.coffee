Varying = require('../core/varying').Varying
util = require('../util/util')

# A `Reference` squirrels away the idea of a value that is resolvable but
# should be explicitly resolved (and possibly needs input). It exposes as its
# value the resolver, which when invoked gets replaced with the resolved value.
class Reference extends Varying
  @resolverClass: Resolver
  constructor: (@inner, @flatValue) ->
    super( value: this._resolver() )

  _resolver: -> new this.constructor.resolverClass(this, this.inner)



# A `Resolver` has simply a method called `resolve` which triggers its
# replacement with whatever it is trying to resolve within its parent
# `Reference`.
#
# The default implementation doesn't do anything useful. See the
# `RequestResolver` and `RequestReference` for the base use case.
class Resolver
  constructor: (@parent, @value) ->
  resolve: -> this.parent.setValue(this.value)


# A `Resolver` that resolves `Request`s. It takes the `app` and kicks off the
# request before resolution.
class RequestResolver extends Resolver
  constructor: (@parent, @request) ->
  resolve: (app) ->
    store = app.getStore(this.request)

    if store?
      store.handle()
      this.parent.setValue(this.request.map((result) -> result.successOrElse(null)))
    else
      this.parent.setValue(null)

class RequestReference extends Reference
  @resolverClass: RequestResolver


# A `ModelResolver` gives in the context of the model an attribute is a part
# of. This becomes useful for example when deserializing, where you don't have
# context on what the eventual model is that you're interacting with.
class ModelResolver extends Resolver
  constructor: (@parent, @map) ->
  resolve: (model) ->
    this.parent.setValue(map(model))

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

