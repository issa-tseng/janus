
util = require('../util/util')
Base = require('../core/base').Base

Endpoint = require('./endpoint').Endpoint

# silliest "interface" class ever.
class Handler extends Base
  constructor: -> super()

  handler: ->

  handler: -> ->

class HttpHandler extends Handler
  constructor: (@endpoint) -> super()

  handle: (request, response, params) ->
    this.endpoint.handle({
      url: request.url,
      params: params,
      headers: request.headers,
      requestStream: request.request,
      responseStream: response.response
    }, (result) ->
      response.writeHead(result.httpCode, { 'Content-Type': 'text/html' })
      response.write(result.content)
      response.end()
    )

  # hooray for empty higher-order functions!
  handler: ->
    self = this
    (params...) -> self.handle(this.req, this.res, params)

util.extend(module.exports,
  Handler: Handler
  HttpHandler: HttpHandler
)

