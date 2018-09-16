{ Varying } = require('../core/varying')
{ identity, isFunction, isNumber } = require('../util/util')
types = require('../core/types')

# a plain data storage class. really, there is no need to derive from this or
# pay it any attention at all.
class Request
  constructor: (@options) ->

  type: types.operation.read()
  signature: undefined # caching signature.
  cacheable: true # for mutation requests, can opt not to save the result.
  expires: undefined

Resolver = {
  # given some number of resolvers, tries each one until it gets a result. returning
  # null indicates that the resolver was unable to resolve the request.
  oneOf: (resolvers...) -> (request) ->
    for resolver in resolvers
      result = resolver(request)
      return result if result?
    null

  # given a caching class that has two methods:
  # resolve(request: Request): Varying?
  # caching(request: Request, result: Varying?): Void
  # will attempt to hit cache.resolve() first, then try the given resolver, in which case
  # it will call cache.cache() so it can track the result.
  caching: (cache, resolver) -> (request) ->
    if (hit = cache.resolve(request))?
      hit
    else
      result = resolver(request)
      cache.cache(request, result) if result?
      result

  # given a library, attempts to get a resolver from the library and then use it.
  fromLibrary: (library) -> (request) -> library.get(request)?(request)

  # given a dom node which contains elements with an id of the caching signature, will
  # attempt to fulfill requests from document. invalidates nodes when relevant.
  fromDom: (dom, deserialize = identity) -> (request) ->
    signature = request.signature?()
    return unless signature?

    cacheNode = dom.children("##{signature}")
    return if cacheNode.length is 0

    if types.operation.read.match(request.type)
      new Varying(types.result.success(deserialize(cacheNode.text())))
    else
      cacheNode.remove()
      null
}

# standard cache, generally useful for all purposes. respects all request properties:
# type, signature, cacheable, and expires. simply stores results in a map.
class MemoryCacheResolver
  constructor: ->
    this._cache = {}
    this._expires = {}

  resolve: (request) ->
    signature = request.signature?()
    return unless signature?
    return if (expires = this._expires[signature])? and (expires < (new Date()).getTime())
    this._cache[signature]

  cache: (request, result) ->
    signature = request.signature?()
    return unless signature?

    if types.operation.read.match(request.type) and this._cache[signature] isnt result
      this._set(signature, result, request.expires)

    else if types.operation.mutate.match(request.type)
      # where invalidate() is more for weird cases, we always assume mutating an object
      # should invalidate its corresponding cache.
      this._cache[signature] = null

      if types.operation.delete.match(request.type)
        # do nothing, we are done.

      else if request.cacheable is true
        self = this
        result.react((inner) ->
          types.result.success.match(inner, -> self._set(signature, result, request.expires))
          this.stop() if types.result.complete.match(inner)
        )

    null

  _set: (signature, value, expires) ->
    this._cache[signature] = value
    if expires?
      after = if isFunction(expires) then expires() else expires
      this._expires[signature] = (new Date()).getTime() + (after * 1000) if isNumber(after)
    null

# for the export, don't have multiple toplevel Resolver things:
Resolver.MemoryCache = MemoryCacheResolver

module.exports = { Request, Resolver, MemoryCacheResolver }

