
util = require('../util/util')
Base = require('../core/base').Base

Endpoint = require('./endpoint').Endpoint

class HttpHandler extends Base
  constructor: (@endpoint) -> super()

  handle: (request, response) ->
    this.endpoint.handle({ headers: request.headers, requestStream: request }, (result) ->
      response.writeHead(result.httpCode, { 'Content-Type': 'text/html' })
      response.write(result.content)
      response.end()
    )

  # hooray for empty higher-order functions!
  handler: ->
    self = this
    -> self.handle(this.req, this.res)

util.extend(module.exports,
  HttpHandler: HttpHandler
)

