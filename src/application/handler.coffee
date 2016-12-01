Base = require('../core/base').Base
Endpoint = require('./endpoint').Endpoint


# silliest "interface" class ever.
class Handler extends Base
  constructor: -> super()

  handler: -> ->

class HttpHandler extends Handler
  constructor: (@endpoint) -> super()

  handle: (request, response, params) ->
    handled = false

    this.endpoint.handle({
      url: request.url,
      params: params,
      headers: request.headers,
      requestStream: request.request,
      responseStream: response.response
    }, (result) ->
      return if handled is true
      handled = true

      response.writeHead(result.httpCode, { 'Content-Type': 'text/html' })
      response.write(result.content)
      response.end()
    )

  # hooray for empty higher-order functions!
  handler: ->
    self = this
    (params...) -> self.handle(this.req, this.res, params)


module.exports = { Handler, HttpHandler }

