
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
  Handler: Handler
  HttpHandler: HttpHandler
)

