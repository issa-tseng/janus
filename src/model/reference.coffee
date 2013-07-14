Varying = require('../core/varying').Varying
util = require('../util/util')

# A `Resolver` has simply a method called `resolve` which triggers its
# replacement with whatever it is trying to resolve within its parent
# `Reference`.
#
# The default implementation doesn't do anything useful. See the
# `RequestResolver` and `RequestReference` for the base use case.
class Resolver
  constructor: (@parent, @value) ->
  resolve: -> this.parent.setValue(this.value)

# A `Reference` squirrels away the idea of a value that is resolvable but
# should be explicitly resolved (and possibly needs input). It exposes as its
# value the resolver, which when invoked gets replaced with the resolved value.
class Reference extends Varying
  @resolverClass: Resolver
  constructor: (value) ->
    resolver = new this.constructor.resolverClass(this, value)
    super( value: resolver )


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

# The `Reference` companion to the above.
class RequestReference extends Reference
  @resolverClass: RequestResolver

util.extend(module.exports,
  Resolver: Resolver
  Reference: Reference

  RequestResolver: RequestResolver
  RequestReference: RequestReference
)

