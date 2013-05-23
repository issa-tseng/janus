
util = require('../util/util')
Base = require('../core/base').Base

StoreManifest = require('./manifest').StoreManifest

class EndpointResponse
  constructor: (@content) ->

class OkResponse extends EndpointResponse
  httpCode: 200
class InvalidRequestResponse extends EndpointResponse
  httpCode: 400
class UnauthorizedResponse extends EndpointResponse
  httpCode: 401
class ForbiddenResponse extends EndpointResponse
  httpCode: 403
class NotFoundResponse extends EndpointResponse
  httpCode: 404
class InternalErrorResponse extends EndpointResponse
  httpCode: 500

# I really really dislike this, but I can't think of a more elegant solution at
# the moment for cleanly handling the fact that libraries could be shared
# across requests, and I need to distinguish which fetches are associated with
# which requests.
class LibraryReadProxy extends Base
  constructor: (@library) ->
    super()

  get: (obj, options) ->
    result = this.library.get(obj, options)
    this.emit('got', result, result.constructor, options) if result?
    result

class Endpoint extends Base
  constructor: (@storeLibrary, @pageModelClass, @pageLibrary, @viewLibrary) ->
    super()

  handle: (env, respond) ->
    storeProxy = new LibraryReadProxy(this.storeLibrary)
    manifest = new StoreManifest(storeProxy)
    manifest.on('allComplete', => this.finish(pageModel, pageView, manifest, respond))

    pageModel = new this.pageModelClass({ env: env }, { storeLibrary: this.storeLibrary })
    pageView = this.pageLibrary.get(pageModel, context: env.context, constructorOpts: { viewLibrary: this.viewLibrary })

    # grab dom before resolving so that rendering happens as objects come in.
    dom = pageView.artifact()
    pageModel.resolve()

    # return dom immediately if the upstream needs/wants it
    dom

  finish: (pageModel, pageView, manifest, respond) ->
    respond(new OkResponse(pageView.markup()))

  @factoryWith: (storeLibrary, pageLibrary, viewLibrary) ->
    self = this
    (pageModelClass) -> new self(storeLibrary, pageModelClass, pageLibrary, viewLibrary)


util.extend(module.exports,
  Endpoint: Endpoint

  responses:
    EndpointResponse: EndpointResponse
    InvalidRequestResponse: InvalidRequestResponse
    UnauthorizedResponse: UnauthorizedResponse
    ForbiddenResponse: ForbiddenResponse
    NotFoundResponse: NotFoundResponse
    InternalErrorResponse: InternalErrorResponse
)

