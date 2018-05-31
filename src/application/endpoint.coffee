types = require('../util/types')
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
    app = this.initApp(env)

    # create a manifest to track created objects and request completion.
    manifest = new StoreManifest(app)
    manifest.on('allComplete', => this.finish(pageModel, pageView, manifest, respond))
    manifest.on('requestComplete', (request) =>
      if types.result.failure.match(request.value) and request.options.fatal is true
        this.error(request, respond)
    )

    # make our app, our pageModel, and its pageView.
    pageModel = this.initPageModel(env, app, respond)
    pageView = this.pageLibrary.get(pageModel, context: env.context, options: { app: app })

    # grab dom before resolving so that rendering happens as objects come in.
    # TODO: not real happy about this method, or passing env thorugh, etc.
    dom = this.initPageView(pageView, env)
    pageModel.resolve()

    # return dom immediately if the upstream needs/wants it
    dom

  # we shadow the app so we get our own domain for vend events, so we can track stores.
  initApp: (env) -> this.app.shadow()

  initPageModel: (env, app, respond) -> new this.pageModelClass({ env: env }, { app: app })

  initPageView: (pageView, env) -> pageView.artifact()

  finish: (pageModel, pageView, manifest, respond) ->
    respond(new OkResponse(pageView.markup()))

  error: (request, respond) ->
    respond(new InternalErrorResponse())

  @factoryWith: (pageLibrary, app) ->
    self = this
    (pageModelClass) -> new self(pageModelClass, pageLibrary, app)


module.exports = {
  Endpoint: Endpoint

  responses:
    EndpointResponse: EndpointResponse

    OkResponse: OkResponse
    InvalidRequestResponse: InvalidRequestResponse
    UnauthorizedResponse: UnauthorizedResponse
    ForbiddenResponse: ForbiddenResponse
    NotFoundResponse: NotFoundResponse
    InternalErrorResponse: InternalErrorResponse
}

