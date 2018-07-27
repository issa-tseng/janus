types = require('../../lib/core/types')
{ Varying } = require('../../lib/core/varying')
{ Request, Resolver, MemoryCacheResolver } = require('../../lib/model/resolver')
{ oneOf, caching, fromLibrary, fromDom } = Resolver

class SignaturedRequest extends Request
  signature: -> 'signature'
  @of: (x) -> class extends this
    signature: -> x

class DeletingRequest extends SignaturedRequest
  type: types.operation.delete()

class UpdatingRequest extends SignaturedRequest
  type: types.operation.update()

describe 'Resolver', ->
  describe 'one-of resolver', ->
    it 'should try each given resolver and return the first success', ->
      oneOf((-> null), (-> null), (-> 42))().should.equal(42)

    it 'should pass the request to each resolver', ->
      result = []
      oneOf(((x) -> result.push(x); null), ((x) -> result.push(x); null), (-> true))(42)
      result.should.eql([ 42, 42 ])

    it 'should return null if nothing was successful', ->
      (oneOf((->), (->), (->))() is null).should.equal(true)

  describe 'caching resolver', ->
    it 'should first try the cache resolver with the request and return if cachehit', ->
      arg = null
      called = false
      caching({ resolve: (x) -> arg = x; 42 }, (-> called = true))(1).should.equal(42)
      arg.should.equal(1)
      called.should.equal(false)

    it 'should fall back on the real resolver if cachemiss', ->
      arg = null
      caching({ resolve: (->), cache: (->) }, ((x) -> arg = x; 42))(1).should.equal(42)
      arg.should.equal(1)

    it 'should cache the result if cachemiss and subsequent success', ->
      request = result = null
      caching({ resolve: (->), cache: ((x, y) -> request = x; result = y) }, (-> 42))(1)
      request.should.equal(1)
      result.should.equal(42)

    it 'should not try to cache if everything misses', ->
      called = false
      should.not.exist(caching({ resolve: (->), cache: (-> called = true) }, (->))())
      called.should.equal(false)

  describe 'library resolver', ->
    it 'should ask the library about the request', ->
      called = null
      fromLibrary({ get: (x) -> called = x })(42)
      called.should.equal(42)

    it 'should return null unless the library gives a function', ->
      should.not.exist(fromLibrary({ get: -> 12 })())
      should.not.exist(fromLibrary({ get: -> { hi: true } })())

    it 'should call and return the library function with the request if given', ->
      fromLibrary({ get: -> -> 42 })().should.equal(42)

  describe 'dom resolver', ->
    it 'should not do anything if the request has no signature', ->
      should.not.exist(fromDom()({ isRequest: true }))

    it 'should look for children of the appropriate dom id', ->
      called = null
      fromDom({ children: (x) -> called = x; { length: 0 } })({ signature: -> 'test' })
      called.should.equal('#test')

    it 'should do nothing if no child was found', ->
      should.not.exist(fromDom({ children: -> { length: 0 } })({ signature: -> 'test' }))

    it 'should return success(the node text) if found and the request is fetch', ->
      result = fromDom({ children: -> { length: 1, text: -> 'cached' } })(new SignaturedRequest())
      result.isVarying.should.equal(true)
      types.result.success.match(result.get()).should.equal(true)
      result.get().get().should.equal('cached')

    it 'should use the given deserializer if it exists', ->
      result = fromDom({ children: -> { length: 1, text: -> 'cached' } }, (x) -> { x })(new SignaturedRequest())
      result.get().get().should.eql({ x: 'cached' })

    it 'should remove the node and return nothing if found and the request modifies', ->
      removed = false
      should.not.exist(fromDom({ children: -> { length: 1, remove: -> removed = true } })(new UpdatingRequest()))
      removed.should.equal(true)

  describe 'memory cache resolver', ->
    it 'should return nothing on cache miss', ->
      should.not.exist((new MemoryCacheResolver()).resolve(new SignaturedRequest()))

    it 'should cache and return fetch results', ->
      cache = new MemoryCacheResolver()
      cache.cache(new SignaturedRequest(), 42)
      cache.resolve(new SignaturedRequest()).should.equal(42)

    it 'should not return nonmatching fetch results', ->
      cache = new MemoryCacheResolver()
      cache.cache(new SignaturedRequest(), 42)
      should.not.exist(cache.resolve(new (SignaturedRequest.of('other'))))

    it 'should expire fetch requests if requested', (done) ->
      class ExpiringRequest extends SignaturedRequest
        expires: 0
      cache = new MemoryCacheResolver()
      cache.cache(new ExpiringRequest(), 42)
      cache.resolve(new ExpiringRequest()).should.equal(42)
      setTimeout((->
        should.not.exist(cache.resolve(new ExpiringRequest()))
        done()
      ), 0)

    it 'should accept a function to determine cache expiration', (done) ->
      class ExpiringRequest extends SignaturedRequest
        expires: -> 0
      cache = new MemoryCacheResolver()
      cache.cache(new ExpiringRequest(), 42)
      cache.resolve(new ExpiringRequest()).should.equal(42)
      setTimeout((->
        should.not.exist(cache.resolve(new ExpiringRequest()))
        done()
      ), 0)

    it 'should invalidate a cache entry if a mutating request comes through', ->
      class NonCachingUpdatingRequest extends UpdatingRequest
        cacheable: false

      cache = new MemoryCacheResolver()
      cache.cache(new SignaturedRequest(), 42)
      cache.resolve(new SignaturedRequest()).should.equal(42)

      cache.cache(new NonCachingUpdatingRequest())
      should.not.exist(cache.resolve(new SignaturedRequest()))

    it 'should attach to the request result if it is cacheable', ->
      v = new Varying()
      cache = new MemoryCacheResolver()
      cache.cache(new UpdatingRequest(), v)

      should.not.exist(cache.resolve(new SignaturedRequest()))
      v.set(types.result.success(42))
      cache.resolve(new SignaturedRequest()).should.equal(v)

    it 'should not attach to the request result if it is not cacheable', ->
      class NonCachingUpdatingRequest extends UpdatingRequest
        cacheable: false

      v = new Varying()
      cache = new MemoryCacheResolver()
      cache.cache(new NonCachingUpdatingRequest(), v)
      v.set(types.result.success(42))
      should.not.exist(cache.resolve(new SignaturedRequest()))

    it 'should never attach to the request result for delete requests', ->
      v = new Varying()
      cache = new MemoryCacheResolver()
      cache.cache(new SignaturedRequest(), 42)
      cache.cache(new DeletingRequest(), v)
      v.set(types.result.success(42))
      should.not.exist(cache.resolve(new SignaturedRequest()))

    it 'should not attach to the request result if it fails', ->
      v = new Varying()
      cache = new MemoryCacheResolver()
      cache.cache(new UpdatingRequest(), v)
      v.set(types.result.failure(42))
      should.not.exist(cache.resolve(new SignaturedRequest()))

