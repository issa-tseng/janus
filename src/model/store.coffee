
util = require('../util/util')
types = require('../util/types')
Base = require('../core/base').Base
Model = require('../model/model').Model
List = require('../collection/list').List
Varying = require('../core/varying').Varying


# The class that is actually instantiated to begin a request. There should be
# one `Request` classtype for each possible operation, with the constructor
# likely customized to pass in the information relevant to that request.
class Request extends Varying
  constructor: (@options = {}) ->
    super()
    this.value = types.result.init()

  signature: ->

# `Store`s handle requests. Generally, unless you're really clever and/or start
# mucking with reflection, you'll instantiate one `Store` per possible
# `Request`, and provide a handler for each.
#
# These are then fed to the `storeLibrary` as singletons to be handled against
# for each request.
class Store extends Base
  constructor: (@request, @options = {}) ->
    super()

  # Handle a request.
  handle: ->
    handled = this._handle()
    this.emit('requesting', this.request) if handled is Store.Handled
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
  constructor: (@request, @maybeStores = [], @options = {}) ->
    super(@request, @options)

  _handle: ->
    handled = Store.Unhandled
    (handled = maybeStore.handle(this.request)) for maybeStore in this.maybeStores when handled isnt Store.Handled

    if handled is Store.Unhandled
      request.set(types.result.error("No handler was available!")) # TODO: actual error types

    handled


# This `Store` snoops in on requests passing through it to store away the
# result for subsequent requests of the same object. It knows to discard its
# cache for an object if that object gets written to or deleted.
class MemoryCacheStore extends Store
  # we take no request or options.
  constructor: ->
    super()

  _cache: -> this._cache$ ?= {}
  _invalidates: -> this._invalidates$ ?= new List()

  handle: (request) ->
    signature = request.signature()

    if (request instanceof CreateRequest) or (request instanceof UpdateRequest) or (request instanceof DeleteRequest)
      # mutation query.
      # first, check if the handling of this request means something existing
      # must invalidate.
      for cached in this._invalidates().list.slice() when cached.invalidate(request)
        delete this._cache()[cached.signature()]
        this._invalidates().remove(cached)


    if signature?
      # we have a signature to work with; cool.

      if request instanceof FetchRequest
        hit = this._cache()[signature]
        if hit?
          # cache hit. bind against whichever request we already have that
          # looks identical.
          # HACK: temp fix for race condition.
          setTimeout((->request.set(hit)), 0) unless hit is request
          Store.Handled

        else
          # cache miss, but a fetch query. store away our result.
          this._cache()[signature] = request

          # if the request indicates that its cache can expire, expire after
          # that many seconds.
          if request.expires?
            after = if util.isFunction(request.expires) then request.expires() else request.expires
            setTimeout((=> delete this._cache()[signature]), after * 1000) if util.isNumber(after)

          # if the request indicates that its cache can invalidate, add it to
          # the registration pool of checkers.
          if request.invalidate?
            this._invalidates().add(request)

          Store.Unhandled

      else if (request instanceof CreateRequest) or (request instanceof UpdateRequest) or (request instanceof DeleteRequest)
        # clear out our cache and set the result only if we succeed. otherwise,
        # leave it clear.
        delete this._cache()[signature]

        # we allow requests to request not to saveback to the cache in case the
        # server doesn't give us a full response.
        if request.cacheResult isnt false and !(request instanceof DeleteRequest)
          request.react((state) => this._cache()[signature] = state if state == 'success')

        Store.Unhandled

      else
        # delete query, or some unknown query type. clear cache and bail.
        delete this._cache()[signature]
        Store.Unhandled

    else
      # don't do anything if the object doesn't correctly generate signatures.
      # then again, why are you including a caching layer if you're not going to
      # handle it?

      Store.Unhandled

class OnPageCacheStore extends Store
  # we take no request or options.
  constructor: ->
    super()

  _dom: ->

  handle: (request) ->
    signature = request.signature()

    if signature?
      cacheDom = this._dom().find("> ##{signature}")
      if cacheDom.length > 0
        if request instanceof FetchRequest
          request.set(types.result.success(cacheDom.text()))
          Store.Handled
        else
          cacheDom.remove()
          Store.Unhandled
      else
        Store.Unhandled
    else
      Store.Unhandled


module.exports = {
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
}

