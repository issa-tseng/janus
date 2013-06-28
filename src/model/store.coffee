
util = require('../util/util')
Base = require('../core/base').Base
Model = require('../model/model').Model
Varying = require('../core/varying').Varying


# A set of classes to help track what the status of the request is, and provide
# meaningful views against each.
class RequestState
  successOrElse: (x) -> if util.isFunction(x) then x(this) else x

class PendingState extends RequestState
class ProgressState extends PendingState
  constructor: (@progress) ->
  map: (f) -> new ProgressState(f(this.progress))

class CompleteState extends RequestState
class SuccessState extends CompleteState
  constructor: (@result) ->
  map: (f) -> new SuccessState(f(this.result))
  successOrElse: -> this.result
class ErrorState extends CompleteState
  constructor: (@error) ->
  map: (f) -> new ErrorState(f(this.error))


# The class that is actually instantiated to begin a request. There should be
# one `Request` classtype for each possible operation, with the constructor
# likely customized to pass in the information relevant to that request.
class Request extends Varying
  constructor: ->
    super()
    this.value = Request.state.Pending

  signature: ->

  # by default, first deserialize the response body before passing it through
  # to the underlying implementation.
  setValue: (response) -> super(this.deserialize(response))

  # default parsing implementation, reads success bodies as entities based on
  # attribute definition.
  deserialize: (response) ->
    if response instanceof Request.state.type.Success
      response.map((data) => this.constructor.modelClass.deserialize(data))

    else
      # everything else just goes through.
      # TODO: This should generate an object too. How does that happen?
      response

  # the default parse implementation uses the entity type declared here to
  # read in its attributes and make parsing decisions.
  @modelClass: Model

  # some default states that request may be in. feel free to add in your own.
  @state:
    Pending: new PendingState()
    Progress: (progress) -> new ProgressState(progress)

    Complete: new CompleteState()
    Success: (result) -> new SuccessState(result)
    Error: (error) -> new ErrorState(error)

    type:
      Pending: PendingState
      Progress: ProgressState

      Complete: CompleteState
      Success: SuccessState
      Error: ErrorState



# `Store`s handle requests. Generally, unless you're really clever and/or start
# mucking with reflection, you'll instantiate one `Store` per possible
# `Request`, and provide a handler for each.
#
# These are then fed to the `storeLibrary` as singletons to be handled against
# for each request.
class Store extends Base
  constructor: (@request) -> super()

  # Handle a request.
  handle: ->
    handled = this._handle()

    # flashing the lights to let people know a request is going down.
    this.emit('requesting', this.request) if handled is Store.Handled
    # WE HAVE A DEEAAAALLL!!

    handled

  # `handle` return states to let us know whether we were actually capable of
  # handling the request or not.
  @Handled = {}
  @Unhandled = {}



# And now some standard request and store types:

# common request types.
class FetchRequest extends Request
class CreateRequest extends Request
class UpdateRequest extends Request
class DeleteRequest extends Request


# common stores.

# A quick way to implement multiple `Store` strategies. With this, a store can
# return a `Handled` or an `Unhandled` result to indicate whether we should
# fall through to the next handler. A neat trick here is for a caching layer
# to return `Unhandled` on a cache miss, but to listen on the `Request` that it
# got a peek at to then cache a result if available.
class OneOfStore extends Store
  @handlers: []

  _handler: (request) ->
    handled = Store.Unhandled
    (handled = handler(request)) for handler in this.constructor.handlers when handled isnt Store.Handled

    if handled is Store.Unhandled
      request.setValue(Request.state.Error("No handler was available!")) # TODO: actual error types

    handled


# This `Store` snoops in on requests passing through it to store away the
# result for subsequent requests of the same object. It knows to discard its
# cache for an object if that object gets written to or deleted.
class MemoryCacheStore extends Store
  _cache: -> {}

  _handle: (request) ->
    signature = request.signature()

    if signature?
      # we have a signature to work with; cool.

      if request instanceof FetchRequest
        if this._cache()[signature]?
          # cache hit. set a successful result and proclaim our success.
          request.setValue(Request.state.Success(this._cache()[signature]))
          Store.Handled

        else
          # cache miss, but a fetch query. listen on the result and chain out.
          request.on 'changed', (state) =>
            this._cache()[signature] = state.result if state instanceof Request.state.type.Success
          Store.Unhandled

      else if (request instanceof CreateRequest) or (request instanceof UpdateRequest)
        # mutation query. clear out our cache and listen on the result.
        delete this._cache()[signature]
        request.on 'changed', (state) =>
          this._cache()[signature] = state.result if state instanceof Request.state.type.Success
        Store.Unhandled

      else
        # delete query, or some unknown query type. cleare cache and bail.
        delete this._cache()[signature]
        Store.Unhandled

    else
      # don't do anything if the object doesn't correctly generate signatures.
      # then again, why are you including a caching layer if you're not going to
      # handle it?

      Store.Unhandled

class OnPageCacheStore extends Store
  constructor: (@request) ->
    super()

  _dom: ->

  _handle: (request) ->
    signature = request.signature()

    if signature?
      cacheDom = this._dom().find("> ##{signature}")
      if cacheDom.length > 0
        if request instanceof FetchRequest
          request.setValue(Request.state.Success(cacheDom.text()))
          Store.Handled
        else
          cacheDom.remove()
          Store.Unhandled
      else
        Store.Unhandled
    else
      Store.Unhandled


util.extend(module.exports,
  Request: Request
  Store: Store

  OneOfStore: OneOfStore
  MemoryCacheStore: MemoryCacheStore
  OnPageCacheStore: OnPageCacheStore

  request:
    FetchRequest: FetchRequest
    CreateRequest: CreateRequest
    UpdateRequest: UpdateRequest
    DeleteRequest: DeleteRequest
)

