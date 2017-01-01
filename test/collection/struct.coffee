should = require('should')

{ Varying } = require('../../lib/core/varying')
{ Struct } = require('../../lib/collection/struct')
{ KeyList } = require('../../lib/collection/enumeration')

describe 'Struct', ->
  describe 'core', ->
    it 'should construct', ->
      (new Struct()).should.be.an.instanceof(Struct)

    it 'should construct with an attribute bag', ->
      (new Struct( test: 'attr' )).attributes.test.should.equal('attr')

    it 'should call preinitialize before attributes are populated', ->
      result = -1
      class TestStruct extends Struct
        _preinitialize: -> result = this.get('a')

      new TestStruct({ a: 42 })
      should(result).equal(null)

    it 'should call initialize after attributes are populated', ->
      result = -1
      class TestStruct extends Struct
        _initialize: -> result = this.get('a')

      new TestStruct({ a: 42 })
      result.should.equal(42)

  describe 'attribute', ->
    describe 'get', ->
      it 'should be able to get a shallow attribute', ->
        struct = new Struct( vivace: 'brix' )
        struct.get('vivace').should.equal('brix')

      it 'should be able to get a deep attribute', ->
        struct = new Struct( cafe: { vivace: 'brix' } )
        struct.get('cafe.vivace').should.equal('brix')

      it 'should return null on nonexistent attributes', ->
        struct = new Struct( broad: 'way' )
        (struct.get('vivace') is null).should.be.true
        (struct.get('cafe.vivace') is null).should.be.true

    describe 'set', ->
      it 'should be able to set a shallow attribute', ->
        struct = new Struct()
        struct.set('colman', 'pool')

        struct.attributes.colman.should.equal('pool')
        struct.get('colman').should.equal('pool')

      it 'should be able to set a deep attribute', ->
        struct = new Struct()
        struct.set('colman.pool', 'slide')

        struct.attributes.colman.pool.should.equal('slide')
        struct.get('colman.pool').should.equal('slide')

      it 'should be able to set an empty object', ->
        struct = new Struct()
        struct.set('an.obj', {})

        struct.attributes.an.obj.should.eql({})
        struct.get('an.obj').should.eql({})

      it 'should be able to set a deep attribute bag', ->
        struct = new Struct()
        struct.set('colman.pool', { location: 'west seattle', length: { amount: 50, unit: 'meter' } })

        struct.get('colman.pool.location').should.equal('west seattle')
        struct.get('colman.pool.length.amount').should.equal(50)
        struct.get('colman.pool.length.unit').should.equal('meter')

      it 'should accept a bag of attributes', ->
        struct = new Struct()
        struct.set( the: 'stranger' )

        struct.attributes.the.should.equal('stranger')

      it 'should do nothing if setting an equal value', ->
        struct = new Struct( test: 47 )
        evented = false
        struct.on('changed:test', => evented = true)

        struct.set('test', 47)
        evented.should.equal(false)
        struct.set('test', 42)
        evented.should.equal(true)

      it 'should deep write all attributes in a given bag', ->
        struct = new Struct( the: { stranger: 'seattle' } )
        struct.set( the: { joule: 'apartments' }, black: 'dog' )

        struct.attributes.the.stranger.should.equal('seattle')
        struct.get('the.stranger').should.equal('seattle')

        struct.attributes.the.joule.should.equal('apartments')
        struct.get('the.joule').should.equal('apartments')

        struct.attributes.black.should.equal('dog')
        struct.get('black').should.equal('dog')

    describe 'unset', ->
      it 'should be able to unset an attribute', ->
        struct = new Struct( cafe: { vivace: 'brix' } )
        struct.unset('cafe.vivace')

        (struct.get('cafe.vivace') is null).should.be.true

      it 'should be able to unset an attribute tree', ->
        struct = new Struct( cafe: { vivace: 'brix' } )
        struct.unset('cafe')

        (struct.get('cafe.vivace') is null).should.be.true
        (struct.get('cafe') is null).should.be.true

    describe 'setAll', ->
      it 'should set all attributes in the given bag', ->
        struct = new Struct()
        struct.setAll( the: { stranger: 'seattle', joule: 'apartments' } )

        struct.attributes.the.stranger.should.equal('seattle')
        struct.get('the.stranger').should.equal('seattle')

        struct.attributes.the.joule.should.equal('apartments')
        struct.get('the.joule').should.equal('apartments')

      it 'should clear attributes not in the given bag', ->
        struct = new Struct( una: 'bella', tazza: { di: 'caffe' } )
        struct.setAll( tazza: { of: 'cafe' } )

        should.not.exist(struct.attributes.una)
        (struct.get('una') is null).should.be.true
        should.not.exist(struct.attributes.tazza.di)
        (struct.get('tazza.di') is null).should.be.true

        struct.attributes.tazza.of.should.equal('cafe')
        struct.get('tazza.of').should.equal('cafe')

  describe 'shadowing', ->
    describe 'creation', ->
      it 'should create a new instance of the same struct class', ->
        class TestStruct extends Struct

        struct = new TestStruct()
        shadow = struct.shadow()

        shadow.should.not.equal(struct)
        shadow.should.be.an.instanceof(TestStruct)

      it 'should optionally take a different class to shadow with', ->
        class TestStruct extends Struct

        struct = new Struct()
        shadow = struct.shadow(TestStruct)

        shadow._parent.should.equal(struct)
        shadow.should.be.an.instanceof(TestStruct)

      it 'should return the original of a shadow', ->
        struct = new Struct()
        struct.shadow().original().should.equal(struct)

      it 'should return the original of a shadow\'s shadow', ->
        struct = new Struct()
        struct.shadow().shadow().original().should.equal(struct)

      it 'should return itself as the original if it is not a shadow', ->
        struct = new Struct()
        struct.original().should.equal(struct)

    describe 'attributes', ->
      it 'should return the parent\'s values', ->
        struct = new Struct( test1: 'a' )
        shadow = struct.shadow()

        shadow.get('test1').should.equal('a')

        struct.set('test2', 'b')
        shadow.get('test2').should.equal('b')

      it 'should override the parent\'s values with its own', ->
        struct = new Struct( test: 'x' )
        shadow = struct.shadow()

        shadow.get('test').should.equal('x')
        shadow.set('test', 'y')
        shadow.get('test').should.equal('y')

        struct.get('test').should.equal('x')

      it 'should revert to the parent\'s value on revert()', ->
        struct = new Struct( test: 'x' )
        shadow = struct.shadow()

        shadow.set('test', 'y')
        shadow.get('test').should.equal('y')

        shadow.revert('test')
        shadow.get('test').should.equal('x')

      it 'should do nothing on revert() if there is no parent', ->
        struct = new Struct( test: 'x' )
        struct.revert('test')
        struct.get('test').should.equal('x')

      it 'should return null for values that have been set and unset, even if the parent has values', ->
        struct = new Struct( test: 'x' )
        shadow = struct.shadow()

        shadow.set('test', 'y')
        shadow.get('test').should.equal('y')

        shadow.unset('test')
        (shadow.get('test') is null).should.equal(true)

        shadow.revert('test')
        shadow.get('test').should.equal('x')

      it 'should return null for values that have been directly unset, even if the parent has values', ->
        struct = new Struct( test: 'x' )
        shadow = struct.shadow()

        shadow.unset('test')
        (shadow.get('test') is null).should.equal(true)

      it 'should return a shadow substruct if it sees a struct', ->
        substruct = new Struct()
        struct = new Struct( test: substruct )

        shadow = struct.shadow()
        shadow.get('test').original().should.equal(substruct)

    describe 'watching', ->
      it 'should handle when an inherited attribute value changes', ->
        struct = new Struct( test: 'x' )
        shadow = struct.shadow()

        evented = false
        shadow.watch('test').react (value) ->
          evented = true
          value.should.equal('y')

        struct.set('test', 'y')
        evented.should.equal(true)

      it 'should not fire when an overriden inherited attribute changes', ->
        struct = new Struct( test: 'x' )
        shadow = struct.shadow()

        shadow.set('test', 'y')

        evented = false
        shadow.watch('test').react(-> evented = true)

        struct.set('test', 'z')
        evented.should.equal(false)

      it 'should handle when a skiplevel parent has changed', -> # gh45
        s = new Struct( a: 1 )
        s2 = s.shadow()
        s3 = s2.shadow()

        results = []
        s3.watch('a').reactNow((x) -> results.push(x))

        s.set('a', 2)
        results.should.eql([ 1, 2 ])

      it 'should emit anyChanged when a skiplevel parent has changed', -> # gh45
        s = new Struct()
        s2 = s.shadow()
        s3 = s2.shadow()

        results = []
        s3.on('anyChanged', (args...) -> results.push(args))

        s.set('a', 1)
        results.should.eql([ [ 'a', 1, null ] ])

      it 'should output null rather than NullClass upon change', -> # gh54
        s = new Struct( a: 0 )
        s2 = s.shadow()

        results = []
        s2.on('anyChanged', (key, newValue, oldValue) -> results.push(newValue, oldValue))
        s2.unset('a')
        s2.set('a', 1)
        results.should.eql([ null, 0, 1, null ])

      it 'should update leaves correctly when a branch is removed', ->
        s = new Struct( a: 1, b: { c: 2 })

        results = []
        s.watch('b.c').reactNow((x) -> results.push(x))
        s.unset('b')
        results.should.eql([ 2, null ])

  describe 'enumeration', ->
    it 'should return a KeyList of itself when asked for an enumeration', ->
      s = new Struct( a: 1, b: 2, c: { d: 3 } )
      kl = s.enumeration()
      kl.should.be.an.instanceof(KeyList)
      kl.list.should.eql([ 'a', 'b', 'c.d' ])

    it 'should pass options along appropriately', ->
      s = new Struct( a: 1, b: 2, c: { d: 3 } )
      kl = s.enumeration( scope: 'direct', include: 'all' )
      kl.scope.should.equal('direct')
      kl.include.should.equal('all')

    it 'should return an array of keys when asked to enumerate', ->
      s = new Struct( a: 1, b: 2, c: { d: 3 } )
      ks = s.enumerate()
      ks.should.eql([ 'a', 'b', 'c.d' ])

    it 'should pass option to the static enumerator', ->
      s = new Struct( a: 1, b: 2, c: { d: 3 } )
      s2 = s.shadow()
      s2.set( c: { e: 4 }, f: 5 )
      ks = s.enumerate( scope: 'direct', include: 'all' )
      ks.should.eql([ 'a', 'b', 'c', 'c.d' ])

    it 'should allow the length to be watched', ->
      results = []
      s = new Struct( a: 1, b: 2 )
      s.watchLength().reactNow((x) -> results.push(x))

      s.set('c', 3)
      s.unset('b')
      results.should.eql([ 2, 3, 2 ])

  describe 'mapping', ->
    describe 'mapPairs', ->
      it 'should provide the appropriate k/v arguments to the mapping function', ->
        called = []
        s = new Struct( a: 1, b: 2, c: { d: 3 } )
        s.mapPairs((k, v) -> called.push(k, v))
        called.should.eql([ 'a', 1, 'b', 2, 'c.d', 3 ])

      it 'should return a Struct with the appropriate mapped values', ->
        s = new Struct( a: 1, b: 2, c: { d: 3 } )
        s2 = s.mapPairs((k, v) -> v + 1)
        s2.should.be.an.instanceof(Struct)
        s2.attributes.should.eql({ a: 2, b: 3, c: { d: 4 } })

      it 'should handle added and removed values', ->
        s = new Struct( a: 1, b: 2, c: { d: 3 } )
        s2 = s.mapPairs((k, v) -> v + 1)

        s.set('c.e.f', 4)
        s2.attributes.should.eql({ a: 2, b: 3, c: { d: 4, e: { f: 5 } } })

        s.unset('b')
        s2.attributes.should.eql({ a: 2, c: { d: 4, e: { f: 5 } } })

        s.unset('c.e')
        s2.attributes.should.eql({ a: 2, c: { d: 4 } })

      it 'should handle changed values', ->
        s = new Struct( a: 1, b: 2, c: { d: 3 } )
        s2 = s.mapPairs((k, v) -> v + 1)

        s.set('c.d', 4)
        s2.attributes.should.eql({ a: 2, b: 3, c: { d: 5 } })

        s.set('c', 8)
        s2.attributes.should.eql({ a: 2, b: 3, c: 9 })

    describe 'flatMapPairs', ->
      it 'should provide the appropriate k/v arguments to the mapping function', ->
        called = []
        s = new Struct( a: 1, b: 2, c: { d: 3 } )
        s.flatMapPairs((k, v) -> called.push(k, v))
        called.should.eql([ 'a', 1, 'b', 2, 'c.d', 3 ])

      it 'should return a Struct with the appropriate mapped values', ->
        s = new Struct( a: 1, b: 2, c: { d: 3 } )
        c = new Varying(1)
        s2 = s.flatMapPairs((k, v) -> c.map((cv) -> v + cv))
        s2.should.be.an.instanceof(Struct)
        s2.attributes.should.eql({ a: 2, b: 3, c: { d: 4 } })

      it 'should handle added and removed values', ->
        s = new Struct( a: 1, b: 2, c: { d: 3 } )
        c = new Varying(1)
        s2 = s.flatMapPairs((k, v) -> c.map((cv) -> v + cv))

        s.set('c.e.f', 4)
        s2.attributes.should.eql({ a: 2, b: 3, c: { d: 4, e: { f: 5 } } })

        s.unset('b')
        s2.attributes.should.eql({ a: 2, c: { d: 4, e: { f: 5 } } })

        s.unset('c.e')
        s2.attributes.should.eql({ a: 2, c: { d: 4 } })

      it 'should handle changed values', ->
        s = new Struct( a: 1, b: 2, c: { d: 3 } )
        c = new Varying(1)
        s2 = s.flatMapPairs((k, v) -> c.map((cv) -> v + cv))

        c.set(2)
        s2.attributes.should.eql({ a: 3, b: 4, c: { d: 5 } })

        s.set('c.d', 4)
        s2.attributes.should.eql({ a: 3, b: 4, c: { d: 6 } })

        c.set(4)
        s2.attributes.should.eql({ a: 5, b: 6, c: { d: 8 } })

        s.set('c', 8)
        s2.attributes.should.eql({ a: 5, b: 6, c: 12 })

      it 'should deregister all watches on destruction', ->
        count = 0
        s = new Struct( a: 1, b: 2, c: { d: 3 } )
        c = new Varying(1)
        s2 = s.flatMapPairs((k, v) -> c.map((cv) -> count += 1; v + cv))

        count.should.equal(3)
        s2.destroy()
        s.set('e', 4)
        count.should.equal(3)

