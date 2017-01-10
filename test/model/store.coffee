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

