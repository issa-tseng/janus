
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

class Endpoint extends Base
  constructor: (@storeLibrary, @pageModelClass, @pageLibrary, @viewLibrary) ->
    super()

  handle: (env, respond) ->
    ourStoreLibrary = this.storeLibrary.newEventBindings()
    manifest = new StoreManifest(ourStoreLibrary)
    manifest.on('allComplete', => this.finish(pageModel, pageView, manifest, respond))

    pageModel = new this.pageModelClass({ env: env }, { storeLibrary: ourStoreLibrary })
    pageView = this.pageLibrary.get(pageModel, context: env.context, constructorOpts: { viewLibrary: this.viewLibrary })

    # grab dom before resolving so that rendering happens as objects come in.
    # TODO: not real happy about this method, or passing env thorugh, etc.
    dom = this.initPageView(pageView, env)
    pageModel.resolve()

    # return dom immediately if the upstream needs/wants it
    dom

  initPageView: (pageView, env) -> pageView.artifact()

  finish: (pageModel, pageView, manifest, respond) ->
    respond(new OkResponse(pageView.markup()))

  @factoryWith: (storeLibrary, pageLibrary, viewLibrary) ->
    self = this
    (pageModelClass) -> new self(storeLibrary, pageModelClass, pageLibrary, viewLibrary)


util.extend(module.exports,
  Endpoint: Endpoint

  responses:
    EndpointResponse: EndpointResponse

    OkResponse: OkResponse
    InvalidRequestResponse: InvalidRequestResponse
    UnauthorizedResponse: UnauthorizedResponse
    ForbiddenResponse: ForbiddenResponse
    NotFoundResponse: NotFoundResponse
    InternalErrorResponse: InternalErrorResponse
)

