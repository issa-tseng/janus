
util = require('../util/util')
Base = require('../core/base').Base

App = require('./app').App
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
  constructor: (@pageModelClass, @pageLibrary, @app) ->
    super()

  handle: (env, respond) ->
    # create an app obj for this request.
    app = this.initApp()

    # create a manifest to track created objects and request completion.
    manifest = new StoreManifest(app.libraries.stores)
    manifest.on('allComplete', => this.finish(pageModel, pageView, manifest, respond))

    # make our app, our pageModel, and its pageView.
    pageModel = new this.pageModelClass({ env: env }, { app: app })
    pageView = this.pageLibrary.get(pageModel, context: env.context, constructorOpts: { app: app })

    # grab dom before resolving so that rendering happens as objects come in.
    # TODO: not real happy about this method, or passing env thorugh, etc.
    dom = this.initPageView(pageView, env)
    pageModel.resolve()

    # return dom immediately if the upstream needs/wants it
    dom

  initApp: ->
    # make our own store library so we can track events on it specifically.
    storeLibrary = this.app.libraries.stores.newEventBindings()
    this.app.withStoreLibrary(storeLibrary)


  initPageView: (pageView, env) -> pageView.artifact()

  finish: (pageModel, pageView, manifest, respond) ->
    respond(new OkResponse(pageView.markup()))

  @factoryWith: (pageLibrary, app) ->
    self = this
    (pageModelClass) -> new self(pageModelClass, pageLibrary, app)


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

