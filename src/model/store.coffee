
{ isFunction, isNumber, isArray } = require('../util/util')
types = require('../util/types')
{ Base } = require('../core/base')
{ Model } = require('../model/model')
{ Map } = require('../collection/map')
{ Varying } = require('../core/varying')


# The class that is actually instantiated to begin a request. There should be
# one `Request` classtype for each possible operation, with the constructor
# likely customized to pass in the information relevant to that request.
class Request extends Varying
  constructor: (@options = {}) ->
    super(types.result.init())

  type: types.operation.fetch()
  signature: ->
  invalidates: undefined
  expires: undefined

# `Store`s handle requests. An instance of a store is initialized for each request
# to be handled, but handling doesn't occur until `handle()` is called. If you
# wish to use the OneOfStore you should return a handled or unhandled type from
# `handle()`. Store classes are then fed to the store library for the application,
# registered against the request class they respectively service.
class Store extends Base
  constructor: (@request) ->
    super()

  handle: ->
    handled = this._handle()
    unless types.handling.unhandled.match(handled)
      this.emit('requesting', this.request)

    handled

  # Override this to actually implement handling.
  _handle: ->


# common stores.

# A quick way to implement multiple `Store` strategies. With this, a store can
# return a `Handled` or an `Unhandled` result to indicate whether we should
# fall through to the next handler. A neat trick here is for a caching layer
# to return `Unhandled` on a cache miss, but to listen on the `Request` that it
# got a peek at to then cache a result if available.
class OneOfStore extends Store
  constructor: (request, maybeStores...) ->
    this.maybeStores = if isArray(maybeStores[0]) then maybeStores[0] else maybeStores
    super(request)

  _handle: ->
    handled = types.handling.unhandled()
    for maybeStore in this.maybeStores
      handled =
        if maybeStore.prototype?
          (new maybeStore(this.request)).handle()
        else
          maybeStore.handle()
      break if types.handling.handled.match(handled)

    unless types.handling.handled.match(handled)
      this.request.set(types.result.failure("No handler was available!")) # TODO: actual error types
      types.handling.unhandled()
    else
      handled


# This `Store` snoops in on requests passing through it to store away the
# result for subsequent requests of the same object. It knows to discard its
# cache for an object if that object gets written to or deleted.
class MemoryCacheStore extends Store
  # we take no request or options.
  constructor: ->
    super()
    this._cache = new Map()

  handle: (request) ->
    signature = request.signature()

    if types.operation.mutate.match(request.type)
      # we're mutating, so we may have to invalidate existing objects.
      for key in this._cache.enumerate() when this._cache.get(key).invalidate?(request) is true
        this._cache.unset(key)

    if signature?
      if types.operation.fetch.match(request.type)
        hit = this._cache.get(signature)
        if hit?
          # cache hit; have our request mirror the hit and we're good.
          request.bind(hit) unless request is hit
          types.handling.handled()

        else
          # cache miss, but a fetch query, so store away our result. set up expiry if relevant.
          this._cache.set(signature, request)

          if request.expires?
            after = if isFunction(request.expires) then request.expires() else request.expires
            setTimeout((=> this._cache.unset(signature)), after * 1000) if isNumber(after)

          types.handling.unhandled()

      else if types.operation.mutate.match(request.type)
        # where invalidate() is more for weird cases, we always assume mutating an object
        # should invalidate its corresponding cache.
        this._cache.unset(signature)

        # we allow requests to request not to saveback to the cache in case the
        # server doesn't give us a full response.
        # TODO: not at all happy with the listening strategy here.
        if request.cacheResult isnt false and !types.operation.delete.match(request.type)
          cache = this._cache
          request.reactLater((result) ->
            cache.set(signature, request) if types.result.success.match(result)
            this.stop() if types.result.complete.match(result)
          )

        types.handling.unhandled()

      else
        # not sure what this is!
        this._cache.unset(signature)
        types.handling.unhandled()

    else
      # if we have no signature, we can never do anything useful for caching.
      types.handling.unhandled()

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
        if types.operation.fetch.match(request.type)
          request.set(types.result.success(cacheDom.text()))
          types.handling.handled()
        else
          cacheDom.remove()
          types.handling.unhandled()
      else
        types.handling.unhandled()
    else
      types.handling.unhandled()


module.exports = {
  Request: Request
  Store: Store

  OneOfStore: OneOfStore
  MemoryCacheStore: MemoryCacheStore
  OnPageCacheStore: OnPageCacheStore
}

