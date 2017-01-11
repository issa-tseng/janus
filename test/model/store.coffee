should = require('should')

{ Request, Store, OneOfStore, MemoryCacheStore, OnPageCacheStore } = require('../../lib/model/store')
{ handling, operation } = types = require('../../lib/util/types')

describe 'request', ->
  it 'should initialize with init state', ->
    types.result.init.match((new Request()).get()).should.equal(true)

  it 'should default to a fetch operation type', ->
    operation.fetch.match((new Request()).type).should.equal(true)

describe 'store', ->
  it 'should take and store a provided request', ->
    request = new Request()
    store = new Store(request)
    store.request.should.equal(request)

  it 'should emit a requesting event with the request', ->
    result = null
    request = new Request()
    store = new Store(request)

    store.on('requesting', (x) -> result = x)
    store.handle()
    result.should.equal(request)

  it 'should not emit requesting if unhandled is returned', ->
    class TestStore extends Store
      _handle: -> handling.unhandled()

    result = null
    request = new Request()
    store = new TestStore(request)

    store.on('requesting', (x) -> result = x)
    store.handle()
    should(result).equal(null)

describe 'one-of store', ->
  it 'should take possible store instances as parameters and call them in turn', ->
    results = []
    class DummyStore extends Store
      _handle: ->
        results.push(this.request)
        types.handling.unhandled()

    store = new OneOfStore({ set: (->) }, (new DummyStore(0)), (new DummyStore(1)), (new DummyStore(2)))
    results.should.eql([])
    store.handle()
    results.should.eql([ 0, 1, 2 ])

  it 'should take possible store classes as parameters and call them in turn', ->
    results = []
    stores = # coffeescript is dummmmmmmb sometimes.
      for i in [0..2]
        do (i) ->
          class extends Store
            _handle: ->
              results.push(i)
              types.handling.unhandled()

    store = new OneOfStore({ set: (->) }, stores)
    results.should.eql([])
    store.handle()
    results.should.eql([ 0, 1, 2 ])

  it 'should return a failure type if no store handled the request', ->
    result = null
    store = new OneOfStore({ set: (x) -> result = x }, Store, Store, Store)
    store.handle()
    types.result.failure.match(result).should.equal(true)

  it 'should itself return a handling type indicating whether it managed to handle or not', ->
    store = new OneOfStore({ set: (x) -> result = x }, Store, Store, Store)
    handling.unhandled.match(store.handle()).should.equal(true)

    class FulfillingStore extends Store
      _handle: -> handling.handled()

    store = new OneOfStore({ set: (x) -> result = x }, Store, FulfillingStore)
    handling.handled.match(store.handle()).should.equal(true)

  it 'should cease calling stores once it is handled', ->
    alarm = false
    class FulfillingStore extends Store
      _handle: -> handling.handled()

    class AlarmingStore extends Store
      _handle: -> alarm = true

    store = new OneOfStore(null, Store, FulfillingStore, AlarmingStore)
    store.handle()
    alarm.should.equal(false)

describe 'memory cache', ->
  describe 'fetching', ->
    it 'should return unhandled and not cache if no signature is given', ->
      store = new MemoryCacheStore()

      ra = new Request()
      handling.unhandled.match(store.handle(ra)).should.equal(true)

      rb = new Request()
      handling.unhandled.match(store.handle(rb)).should.equal(true)

      ra.set(23)
      rb.get().should.not.equal(23)

    it 'should cache and bind like-signatured fetch requests', ->
      class TestRequest extends Request
        constructor: (@sig) -> super()
        signature: -> this.sig

      store = new MemoryCacheStore()

      ra = new TestRequest('aaa')
      handling.unhandled.match(store.handle(ra)).should.equal(true)

      rb = new TestRequest('aaa')
      handling.handled.match(store.handle(rb)).should.equal(true)

      ra.set(777)
      rb.get().should.equal(777)

    it 'should discriminate against differently-signatured requests', ->
      class TestRequest extends Request
        constructor: (@sig) -> super()
        signature: -> this.sig

      store = new MemoryCacheStore()

      ra = new TestRequest('aaa')
      handling.unhandled.match(store.handle(ra)).should.equal(true)

      rb = new TestRequest('bbb')
      handling.unhandled.match(store.handle(rb)).should.equal(true)

      ra.set(787)
      rb.get().should.not.equal(787)

    it 'should expire the request if specified (as a function)', (stop) ->
      class ExpiringRequest extends Request
        constructor: (@sig) -> super()
        signature: -> this.sig
        expires: -> 0
      class TestRequest extends Request
        constructor: (@sig) -> super()
        signature: -> this.sig

      store = new MemoryCacheStore()

      ra = new ExpiringRequest('aaa')
      handling.unhandled.match(store.handle(ra)).should.equal(true)

      rb = new TestRequest('aaa')
      handling.handled.match(store.handle(rb)).should.equal(true)

      setTimeout((->
        rc = new TestRequest('aaa')
        handling.unhandled.match(store.handle(rc)).should.equal(true)

        ra.set(787)
        rc.get().should.not.equal(787)

        stop()
      ), 0)

    it 'should expire the request if specified (as a literal)', (stop) ->
      class ExpiringRequest extends Request
        constructor: (@sig) -> super()
        signature: -> this.sig
        expires: 0
      class TestRequest extends Request
        constructor: (@sig) -> super()
        signature: -> this.sig

      store = new MemoryCacheStore()

      ra = new ExpiringRequest('aaa')
      handling.unhandled.match(store.handle(ra)).should.equal(true)

      rb = new TestRequest('aaa')
      handling.handled.match(store.handle(rb)).should.equal(true)

      setTimeout((->
        rc = new TestRequest('aaa')
        handling.unhandled.match(store.handle(rc)).should.equal(true)

        ra.set(787)
        rc.get().should.not.equal(787)

        stop()
      ), 0)

  describe 'mutation', ->
    it 'should automatically expire the cache upon any mutation request type', ->
      class TestRequest extends Request
        constructor: (@sig, @type) -> super()
        signature: -> this.sig

      for type in [ operation.create(), operation.update(), operation.delete() ]
        store = new MemoryCacheStore()

        ra = new TestRequest('aaa', operation.fetch())
        store.handle(ra)

        handling.handled.match(store.handle(new TestRequest('aaa', operation.fetch()))).should.equal(true)

        rb = new TestRequest('aaa', type)
        handling.unhandled.match(store.handle(rb)).should.equal(true)

        handling.unhandled.match(store.handle(new TestRequest('aaa', operation.fetch()))).should.equal(true)

    it 'should attempt to tap into successful returned results for create and update', ->
      class TestRequest extends Request
        constructor: (@sig, @type) -> super()
        signature: -> this.sig

      for type in [ operation.create(), operation.update() ]
        store = new MemoryCacheStore()

        ra = new TestRequest('aaa', type)
        handling.unhandled.match(store.handle(ra)).should.equal(true)

        ra.set(types.result.success(42))

        rb = new TestRequest('aaa', operation.fetch())
        handling.handled.match(store.handle(rb)).should.equal(true)
        rb.get().value.should.equal(42)

    it 'should not attempt to tap into returned results if cacheResult is false', ->
      class TestRequest extends Request
        constructor: (@sig, @type) -> super()
        signature: -> this.sig
        cacheResult: false

      store = new MemoryCacheStore()

      ra = new TestRequest('aaa', operation.update())
      handling.unhandled.match(store.handle(ra)).should.equal(true)

      ra.set(types.result.success(42))

      rb = new TestRequest('aaa', operation.fetch())
      handling.unhandled.match(store.handle(rb)).should.equal(true)

    it 'should not attempt to tap into returned results for delete requests', ->
      class TestRequest extends Request
        constructor: (@sig, @type) -> super()
        signature: -> this.sig

      store = new MemoryCacheStore()

      ra = new TestRequest('aaa', operation.delete())
      handling.unhandled.match(store.handle(ra)).should.equal(true)

      ra.set(types.result.success(42))

      rb = new TestRequest('aaa', operation.fetch())
      handling.unhandled.match(store.handle(rb)).should.equal(true)

    it 'should not accept the mutated result if it was not successful', ->
      class TestRequest extends Request
        constructor: (@sig, @type) -> super()
        signature: -> this.sig

      store = new MemoryCacheStore()

      ra = new TestRequest('aaa', operation.update())
      handling.unhandled.match(store.handle(ra)).should.equal(true)

      ra.set(types.result.failure(42))

      rb = new TestRequest('aaa', operation.fetch())
      handling.unhandled.match(store.handle(rb)).should.equal(true)

    it 'should stop tapping into mutation requests once they complete once', ->
      class TestRequest extends Request
        constructor: (@sig, @type) -> super()
        signature: -> this.sig

      store = new MemoryCacheStore()

      ra = new TestRequest('aaa', operation.update())
      handling.unhandled.match(store.handle(ra)).should.equal(true)

      ra.set(types.result.failure(42))

      rb = new TestRequest('aaa', operation.fetch())
      handling.unhandled.match(store.handle(rb)).should.equal(true)

      ra.set(types.result.success(42))
      store.handle(rb)
      should(rb.get().value).not.equal(42)

  it 'should uncache and not handle if it gets an unknown operation type', ->
    class TestRequest extends Request
      constructor: (@sig, @type) -> super()
      signature: -> this.sig

    store = new MemoryCacheStore()
    ra = new TestRequest('aaa', operation.fetch())
    store.handle(ra)

    rb = new TestRequest('aaa', 'hello!')
    handling.unhandled.match(store.handle(rb)).should.equal(true)

    handling.unhandled.match(store.handle(new TestRequest('aaa', operation.fetch()))).should.equal(true)

  describe 'manual invalidate', ->
    it 'should call existing requests invalidate method with the request in question', ->
      result = null
      class TestRequest extends Request
        constructor: (@sig, @type) -> super()
        signature: -> this.sig
        invalidate: (req) -> result = req

      store = new MemoryCacheStore()
      ra = new TestRequest('aaa', operation.fetch())
      store.handle(ra)

      rb = new TestRequest('bbb', operation.update())
      store.handle(rb)

      result.should.equal(rb)

    it 'should look over existing cached requests and invalidate them if they say so', ->
      class TestRequest extends Request
        constructor: (@sig, @type, @_inv) -> super()
        signature: -> this.sig
        invalidate: -> this._inv

      store = new MemoryCacheStore()
      ra = new TestRequest('aaa', operation.fetch(), true)
      store.handle(ra)

      rb = new TestRequest('bbb', operation.fetch(), false)
      store.handle(rb)

      rc = new TestRequest('ccc', operation.update(), null)
      store.handle(rc)

      handling.unhandled.match(store.handle(new TestRequest('aaa', operation.fetch(), null))).should.equal(true)
      handling.handled.match(store.handle(new TestRequest('bbb', operation.fetch(), null))).should.equal(true)

describe 'on-page cache store', ->
  it 'should passthrough unhandled signatureless requests', ->
    store = new OnPageCacheStore()
    handling.unhandled.match(store.handle(new Request())).should.equal(true)

  it 'should bail out if the data dom node could not be found', ->
    class TestStore extends OnPageCacheStore
      _dom: -> { find: -> [] }
    class TestRequest extends Request
      constructor: (@sig) -> super()
      signature: -> this.sig

    store = new TestStore()
    handling.unhandled.match(store.handle(new TestRequest('aaa'))).should.equal(true)

  it 'should respond with the contents of the data dom node if found', ->
    selector = null
    class TestStore extends OnPageCacheStore
      _dom: -> { find: (x) -> selector = x; { length: 1, text: -> 'test' } }
    class TestRequest extends Request
      constructor: (@sig) -> super()
      signature: -> this.sig

    store = new TestStore()
    r = new TestRequest('aaa')

    handling.handled.match(store.handle(r)).should.equal(true)
    selector.should.equal('> #aaa')
    r.get().value.should.equal('test')

  it 'should remove the dom node and not handle if given a mutation request', ->
    called = null
    class TestStore extends OnPageCacheStore
      _dom: -> { find: -> { length: 1, remove: -> called = true } }
    class TestRequest extends Request
      constructor: (@sig, @type) -> super()
      signature: -> this.sig

    store = new TestStore()
    r = new TestRequest('aaa')

    handling.unhandled.match(store.handle(r)).should.equal(true)
    called.should.equal(true)

