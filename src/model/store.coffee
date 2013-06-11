
util = require('../util/util')
Base = require('../core/base').Base
Model = require('../model/model').Model
Varying = require('../core/varying').Varying


# `Store`s handle requests. Generally, unless you're really clever and/or start
# mucking with reflection, you'll instantiate one `Store` per possible
# `Request`, and provide a handler for each.
#
# These are then fed to the `storeLibrary` as singletons to be handled against
# for each request.
class Store extends Base
  constructor: (@handler) ->

  # Handle a request.
  handle: (request) ->
    # flashing the lights to let people know a request is going down.
    this.emit('requesting', request)

    # actually handle the thing.
    this.handler(request)

    # return the request in case they want it.
    request

# A quick way to implement multiple `Store` strategies. With this, a store can
# return a `Handled` or an `Unhandled` result to indicate whether we should
# fall through to the next handler. A neat trick here is for a caching layer
# to return `Unhandled` on a cache miss, but to listen on the `Request` that it
# got a peek at to then cache a result if available.
class OneOfStore extends Store
  constructor: (@handlers) ->
    this.handler = (request) ->
      handled = OneOfStore.Unhandled
      (handled = handler(request)) for handler in this.handlers when handled isnt OneOfStore.Handled

      if handled is OneOfStore.Unhandled
        request.setValue(Request.status.Error("No handler was available!")) # TODO: actual error types

  @Handled = {}
  @Unhandled = {}


# A set of classes to help track what the status of the request is, and provide
# meaningful views against each.
class RequestStatus

class Pending extends RequestStatus
class Progress extends Pending
  constructor: (@progress) ->

class Complete extends RequestStatus
class Success extends Complete
  constructor: (@result) ->
class Error extends Complete
  constructor: (@error) ->


# The class that is actually instantiated to begin a request. There should be
# one `Request` classtype for each possible operation, with the constructor
# likely customized to pass in the information relevant to that request.
class Request extends Varying
  constructor: ->
    super()
    this.value = Request.status.Pending

  @status:
    Pending: new Pending()
    Progress: (progress) -> new Progress(progress)

    Complete: new Complete()
    Success: (result) -> new Success(result)
    Error: (error) -> new Error(error)

util.extend(module.exports,
  Store: Store
  Request: Request
)

