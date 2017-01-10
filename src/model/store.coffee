
{ isFunction, isNumber, isArray } = require('../util/util')
types = require('../util/types')
{ Base } = require('../core/base')
{ Model } = require('../model/model')
{ List } = require('../collection/list')
{ Varying } = require('../core/varying')


# The class that is actually instantiated to begin a request. There should be
# one `Request` classtype for each possible operation, with the constructor
# likely customized to pass in the information relevant to that request.
class Request extends Varying
  constructor: (@options = {}) ->
    super(types.result.init())

  type: types.operation.fetch()
  signature: ->

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

  _cache: -> this._cache$ ?= {}
  _invalidates: -> this._invalidates$ ?= new List()

  handle: (request) ->
    signature = request.signature()

    if types.operation.mutate.match(request.type)
      # mutation query.
      # first, check if the handling of this request means something existing
      # must invalidate.
      for cached in this._invalidates().list.slice() when cached.invalidate(request)
        delete this._cache()[cached.signature()]
        this._invalidates().remove(cached)


    if signature?
      # we have a signature to work with; cool.

      if types.operation.fetch.match(request.type)
        hit = this._cache()[signature]
        if hit?
          # cache hit. bind against whichever request we already have that
          # looks identical.
          # HACK: temp fix for race condition.
          setTimeout((->request.set(hit)), 0) unless hit is request
          types.handling.handled()

        else
          # cache miss, but a fetch query. store away our result.
          this._cache()[signature] = request

          # if the request indicates that its cache can expire, expire after
          # that many seconds.
          if request.expires?
            after = if isFunction(request.expires) then request.expires() else request.expires
            setTimeout((=> delete this._cache()[signature]), after * 1000) if isNumber(after)

          # if the request indicates that its cache can invalidate, add it to
          # the registration pool of checkers.
          if request.invalidate?
            this._invalidates().add(request)

          types.handling.unhandled()

      else if types.operation.mutate.match(request.type)
        # clear out our cache and set the result only if we succeed. otherwise,
        # leave it clear.
        delete this._cache()[signature]

        # we allow requests to request not to saveback to the cache in case the
        # server doesn't give us a full response.
        if request.cacheResult isnt false and !types.operation.delete.match(request.type)
          request.react((result) => this._cache()[signature] = result if types.result.success.match(state))

        types.handling.unhandled()

      else
        # delete query, or some unknown query type. clear cache and bail.
        delete this._cache()[signature]
        types.handling.unhandled()

    else
      # don't do anything if the object doesn't correctly generate signatures.
      # then again, why are you including a caching layer if you're not going to
      # handle it?

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

