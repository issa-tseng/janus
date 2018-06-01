should = require('should')

{ Varying } = require('../../lib/core/varying')
{ Map } = require('../../lib/collection/map')
{ KeyList } = require('../../lib/collection/enumeration')

describe 'Map', ->
  describe 'core', ->
    it 'should construct', ->
      (new Map()).should.be.an.instanceof(Map)

    it 'should construct with a data bag', ->
      (new Map( test: 'attr' )).data.test.should.equal('attr')

    it 'should call preinitialize before data is populated', ->
      result = -1
      class TestMap extends Map
        _preinitialize: -> result = this.get('a')

      new TestMap({ a: 42 })
      should(result).equal(null)

    it 'should call initialize after data is populated', ->
      result = -1
      class TestMap extends Map
        _initialize: -> result = this.get('a')

      new TestMap({ a: 42 })
      result.should.equal(42)

  describe 'data', ->
    describe 'get', ->
      it 'should be able to get a shallow key', ->
        map = new Map( vivace: 'brix' )
        map.get('vivace').should.equal('brix')

      it 'should be able to get a deep key', ->
        map = new Map( cafe: { vivace: 'brix' } )
        map.get('cafe.vivace').should.equal('brix')

      it 'should return null on nonexistent keys', ->
        map = new Map( broad: 'way' )
        (map.get('vivace') is null).should.be.true
        (map.get('cafe.vivace') is null).should.be.true

    describe 'set', ->
      it 'should be able to set a shallow key', ->
        map = new Map()
        map.set('colman', 'pool')

        map.data.colman.should.equal('pool')
        map.get('colman').should.equal('pool')

      it 'should be able to set a deep key', ->
        map = new Map()
        map.set('colman.pool', 'slide')

        map.data.colman.pool.should.equal('slide')
        map.get('colman.pool').should.equal('slide')

      it 'should be able to set an empty object', ->
        map = new Map()
        map.set('an.obj', {})

        map.data.an.obj.should.eql({})
        map.get('an.obj').should.eql({})

      it 'should be able to set a deep data bag', ->
        map = new Map()
        map.set('colman.pool', { location: 'west seattle', length: { amount: 50, unit: 'meter' } })

        map.get('colman.pool.location').should.equal('west seattle')
        map.get('colman.pool.length.amount').should.equal(50)
        map.get('colman.pool.length.unit').should.equal('meter')

      it 'should accept a bag of data', ->
        map = new Map()
        map.set( the: 'stranger' )

        map.data.the.should.equal('stranger')

      it 'should do nothing if setting an equal value', ->
        map = new Map( test: 47 )
        evented = false
        map.on('changed:test', => evented = true)

        map.set('test', 47)
        evented.should.equal(false)
        map.set('test', 42)
        evented.should.equal(true)

      it 'should deep write all data in a given bag', ->
        map = new Map( the: { stranger: 'seattle' } )
        map.set( the: { joule: 'apartments' }, black: 'dog' )

        map.data.the.stranger.should.equal('seattle')
        map.get('the.stranger').should.equal('seattle')

        map.data.the.joule.should.equal('apartments')
        map.get('the.joule').should.equal('apartments')

        map.data.black.should.equal('dog')
        map.get('black').should.equal('dog')

      it 'should curry if given only a string key', ->
        map = new Map()
        setter = map.set('test')
        (map.get('test') is null).should.equal(true)

        setter(2)
        map.get('test').should.equal(2)
        setter(4)
        map.get('test').should.equal(4)

    describe 'unset', ->
      it 'should be able to unset a key', ->
        map = new Map( cafe: { vivace: 'brix' } )
        map.unset('cafe.vivace')

        (map.get('cafe.vivace') is null).should.be.true

      it 'should be able to unset a key tree', ->
        map = new Map( cafe: { vivace: 'brix' } )
        map.unset('cafe')

        (map.get('cafe.vivace') is null).should.be.true
        (map.get('cafe') is null).should.be.true

    describe 'setAll', ->
      it 'should set all data in the given bag', ->
        map = new Map()
        map.setAll( the: { stranger: 'seattle', joule: 'apartments' } )

        map.data.the.stranger.should.equal('seattle')
        map.get('the.stranger').should.equal('seattle')

        map.data.the.joule.should.equal('apartments')
        map.get('the.joule').should.equal('apartments')

      it 'should clear keys not in the given bag', ->
        map = new Map( una: 'bella', tazza: { di: 'caffe' } )
        map.setAll( tazza: { of: 'cafe' } )

        should.not.exist(map.data.una)
        (map.get('una') is null).should.be.true
        should.not.exist(map.data.tazza.di)
        (map.get('tazza.di') is null).should.be.true

        map.data.tazza.of.should.equal('cafe')
        map.get('tazza.of').should.equal('cafe')

  describe 'shadowing', ->
    describe 'creation', ->
      it 'should create a new instance of the same map class', ->
        class TestMap extends Map

        map = new TestMap()
        shadow = map.shadow()

        shadow.should.not.equal(map)
        shadow.should.be.an.instanceof(TestMap)

      it 'should optionally take a different class to shadow with', ->
        class TestMap extends Map

        map = new Map()
        shadow = map.shadow(TestMap)

        shadow._parent.should.equal(map)
        shadow.should.be.an.instanceof(TestMap)

      it 'should return the original of a shadow', ->
        map = new Map()
        map.shadow().original().should.equal(map)

      it 'should return the original of a shadow\'s shadow', ->
        map = new Map()
        map.shadow().shadow().original().should.equal(map)

      it 'should return itself as the original if it is not a shadow', ->
        map = new Map()
        map.original().should.equal(map)

    describe 'shadowing', ->
      it 'should return the parent\'s values', ->
        map = new Map( test1: 'a' )
        shadow = map.shadow()

        shadow.get('test1').should.equal('a')

        map.set('test2', 'b')
        shadow.get('test2').should.equal('b')

      it 'should override the parent\'s values with its own', ->
        map = new Map( test: 'x' )
        shadow = map.shadow()

        shadow.get('test').should.equal('x')
        shadow.set('test', 'y')
        shadow.get('test').should.equal('y')

        map.get('test').should.equal('x')

      it 'should revert to the parent\'s value on revert()', ->
        map = new Map( test: 'x' )
        shadow = map.shadow()

        shadow.set('test', 'y')
        shadow.get('test').should.equal('y')

        shadow.revert('test')
        shadow.get('test').should.equal('x')

      it 'should do nothing on revert() if there is no parent', ->
        map = new Map( test: 'x' )
        map.revert('test')
        map.get('test').should.equal('x')

      it 'should return null for values that have been set and unset, even if the parent has values', ->
        map = new Map( test: 'x' )
        shadow = map.shadow()

        shadow.set('test', 'y')
        shadow.get('test').should.equal('y')

        shadow.unset('test')
        (shadow.get('test') is null).should.equal(true)

        shadow.revert('test')
        shadow.get('test').should.equal('x')

      it 'should return null for values that have been directly unset, even if the parent has values', ->
        map = new Map( test: 'x' )
        shadow = map.shadow()

        shadow.unset('test')
        (shadow.get('test') is null).should.equal(true)

      it 'should return a shadow submap if it sees a map', ->
        submap = new Map()
        map = new Map( test: submap )

        shadow = map.shadow()
        shadow.get('test').original().should.equal(submap)

    describe 'watching', ->
      it 'should handle when an inherited value changes', ->
        map = new Map( test: 'x' )
        shadow = map.shadow()

        evented = false
        shadow.watch('test').reactLater((value) ->
          evented = true
          value.should.equal('y')
        )

        map.set('test', 'y')
        evented.should.equal(true)

      it 'should not fire when an overriden inherited value changes', ->
        map = new Map( test: 'x' )
        shadow = map.shadow()

        shadow.set('test', 'y')

        evented = false
        shadow.watch('test').reactLater(-> evented = true)

        map.set('test', 'z')
        evented.should.equal(false)

      it 'should handle when a skiplevel parent has changed', -> # gh45
        s = new Map( a: 1 )
        s2 = s.shadow()
        s3 = s2.shadow()

        results = []
        s3.watch('a').react((x) -> results.push(x))

        s.set('a', 2)
        results.should.eql([ 1, 2 ])

      it 'should emit anyChanged when a skiplevel parent has changed', -> # gh45
        s = new Map()
        s2 = s.shadow()
        s3 = s2.shadow()

        results = []
        s3.on('anyChanged', (args...) -> results.push(args))

        s.set('a', 1)
        results.should.eql([ [ 'a', 1, null ] ])

      it 'should output null rather than NullClass upon change', -> # gh54
        s = new Map( a: 0 )
        s2 = s.shadow()

        results = []
        s2.on('anyChanged', (key, newValue, oldValue) -> results.push(newValue, oldValue))
        s2.unset('a')
        s2.set('a', 1)
        results.should.eql([ null, 0, 1, null ])

      it 'should update leaves correctly when a branch is removed', ->
        s = new Map( a: 1, b: { c: 2 })

        results = []
        s.watch('b.c').react((x) -> results.push(x))
        s.unset('b')
        results.should.eql([ 2, null ])

    describe 'sugar', ->
      it 'should return a shadow when with is called', ->
        s = new Map( a: 1 )
        s.with()._parent.should.equal(s)

      it 'should attach the given data to the shadow instance', ->
        s1 = new Map( a: 1, b: 2 )
        s2 = s1.with( b: 3, c: 4 )

        s1.get('a').should.equal(1)
        s1.get('b').should.equal(2)
        s2.get('a').should.equal(1)
        s2.get('b').should.equal(3)
        s2.get('c').should.equal(4)

  describe 'enumeration', ->
    it 'should return a KeyList of itself when asked for an enumeration', ->
      s = new Map( a: 1, b: 2, c: { d: 3 } )
      kl = s.enumeration()
      kl.should.be.an.instanceof(KeyList)
      kl.list.should.eql([ 'a', 'b', 'c.d' ])

    it 'should pass options along appropriately', ->
      s = new Map( a: 1, b: 2, c: { d: 3 } )
      kl = s.enumeration( scope: 'direct', include: 'all' )
      kl.scope.should.equal('direct')
      kl.include.should.equal('all')

    it 'should return an array of keys when asked to enumerate', ->
      s = new Map( a: 1, b: 2, c: { d: 3 } )
      ks = s.enumerate()
      ks.should.eql([ 'a', 'b', 'c.d' ])

    it 'should pass option to the static enumerator', ->
      s = new Map( a: 1, b: 2, c: { d: 3 } )
      s2 = s.shadow()
      s2.set( c: { e: 4 }, f: 5 )
      ks = s.enumerate( scope: 'direct', include: 'all' )
      ks.should.eql([ 'a', 'b', 'c', 'c.d' ])

    it 'should allow the length to be watched', ->
      results = []
      s = new Map( a: 1, b: 2 )
      s.watchLength().react((x) -> results.push(x))

      s.set('c', 3)
      s.unset('b')
      results.should.eql([ 2, 3, 2 ])

  describe 'mapping', ->
    describe 'mapPairs', ->
      it 'should provide the appropriate k/v arguments to the mapping function', ->
        called = []
        s = new Map( a: 1, b: 2, c: { d: 3 } )
        s.mapPairs((k, v) -> called.push(k, v))
        called.should.eql([ 'a', 1, 'b', 2, 'c.d', 3 ])

      it 'should return a Map with the appropriate mapped values', ->
        s = new Map( a: 1, b: 2, c: { d: 3 } )
        s2 = s.mapPairs((k, v) -> v + 1)
        s2.should.be.an.instanceof(Map)
        s2.data.should.eql({ a: 2, b: 3, c: { d: 4 } })

      it 'should handle added and removed values', ->
        s = new Map( a: 1, b: 2, c: { d: 3 } )
        s2 = s.mapPairs((k, v) -> v + 1)

        s.set('c.e.f', 4)
        s2.data.should.eql({ a: 2, b: 3, c: { d: 4, e: { f: 5 } } })

        s.unset('b')
        s2.data.should.eql({ a: 2, c: { d: 4, e: { f: 5 } } })

        s.unset('c.e')
        s2.data.should.eql({ a: 2, c: { d: 4 } })

      it 'should handle changed values', ->
        s = new Map( a: 1, b: 2, c: { d: 3 } )
        s2 = s.mapPairs((k, v) -> v + 1)

        s.set('c.d', 4)
        s2.data.should.eql({ a: 2, b: 3, c: { d: 5 } })

        s.set('c', 8)
        s2.data.should.eql({ a: 2, b: 3, c: 9 })

    describe 'flatMapPairs', ->
      it 'should provide the appropriate k/v arguments to the mapping function', ->
        called = []
        s = new Map( a: 1, b: 2, c: { d: 3 } )
        s.flatMapPairs((k, v) -> called.push(k, v))
        called.should.eql([ 'a', 1, 'b', 2, 'c.d', 3 ])

      it 'should return a Map with the appropriate mapped values', ->
        s = new Map( a: 1, b: 2, c: { d: 3 } )
        c = new Varying(1)
        s2 = s.flatMapPairs((k, v) -> c.map((cv) -> v + cv))
        s2.should.be.an.instanceof(Map)
        s2.data.should.eql({ a: 2, b: 3, c: { d: 4 } })

      it 'should handle added and removed values', ->
        s = new Map( a: 1, b: 2, c: { d: 3 } )
        c = new Varying(1)
        s2 = s.flatMapPairs((k, v) -> c.map((cv) -> v + cv))

        s.set('c.e.f', 4)
        s2.data.should.eql({ a: 2, b: 3, c: { d: 4, e: { f: 5 } } })

        s.unset('b')
        s2.data.should.eql({ a: 2, c: { d: 4, e: { f: 5 } } })

        s.unset('c.e')
        s2.data.should.eql({ a: 2, c: { d: 4 } })

      it 'should handle changed values', ->
        s = new Map( a: 1, b: 2, c: { d: 3 } )
        c = new Varying(1)
        s2 = s.flatMapPairs((k, v) -> c.map((cv) -> v + cv))

        c.set(2)
        s2.data.should.eql({ a: 3, b: 4, c: { d: 5 } })

        s.set('c.d', 4)
        s2.data.should.eql({ a: 3, b: 4, c: { d: 6 } })

        c.set(4)
        s2.data.should.eql({ a: 5, b: 6, c: { d: 8 } })

        s.set('c', 8)
        s2.data.should.eql({ a: 5, b: 6, c: 12 })

      it 'should deregister all watches on destruction', ->
        count = 0
        s = new Map( a: 1, b: 2, c: { d: 3 } )
        c = new Varying(1)
        s2 = s.flatMapPairs((k, v) -> c.map((cv) -> count += 1; v + cv))

        count.should.equal(3)
        s2.destroy()
        s.set('e', 4)
        count.should.equal(3)

  describe 'deserialize', ->
    it 'should populate the result with the appropriate data', ->
      result = Map.deserialize( a: 1, b: 2, c: { d: 3 } )
      result.data.should.eql({ a: 1, b: 2, c: { d: 3 } })

    it 'should create an instance of a subclass if called from it', ->
      class MyMap extends Map
      MyMap.deserialize({}).should.be.an.instanceof(MyMap)

