should = require('should')

{ Varying } = require('../../lib/core/varying')
{ Map } = require('../../lib/collection/map')
{ List } = require('../../lib/collection/list')
{ KeyList, IndexList, Enumeration } = require('../../lib/collection/enumeration')

describe 'map enumeration', ->
  describe 'keylist', ->
    describe 'key tracking', ->
      it 'should include all initial keys', ->
        s = new Map( a: 1, b: 2, c: 3 )
        kl = new KeyList(s)

        kl.length.should.equal(3)
        for val, idx in [ 'a', 'b', 'c' ]
          kl.at(idx).should.equal(val)

      it 'should include all initial nested value keys', ->
        s = new Map( a: 1, b: 2, c: { d: 3, e: { f: 4 } } )
        kl = new KeyList(s)

        kl.length.should.equal(4)
        for val, idx in [ 'a', 'b', 'c.d', 'c.e.f' ]
          kl.at(idx).should.equal(val)

      it 'should update to reflect new keys', ->
        s = new Map( a: 1, b: { c: 2, d: 3 } )
        kl = new KeyList(s)

        s.set('z', 9)
        kl.length.should.equal(4)
        for val, idx in [ 'a', 'b.c', 'b.d', 'z' ]
          kl.at(idx).should.equal(val)

        s.set('b.e', 4)
        kl.length.should.equal(5)
        for val, idx in [ 'a', 'b.c', 'b.d', 'z', 'b.e' ]
          kl.at(idx).should.equal(val)

      it 'should update to reflect removed keys', ->
        s = new Map( a: 1, b: { c: 2, d: 3 }, e: 4 )
        kl = new KeyList(s)

        s.unset('a')
        kl.length.should.equal(3)
        for val, idx in [ 'b.c', 'b.d', 'e' ]
          kl.at(idx).should.equal(val)

        s.unset('b.d')
        kl.length.should.equal(2)
        for val, idx in [ 'b.c', 'e' ]
          kl.at(idx).should.equal(val)

      it 'should not be affected by changing keys', ->
        s = new Map( a: 1, b: { c: 2, d: 3 }, e: 4 )
        kl = new KeyList(s)

        evented = 0
        kl.on('added', -> evented += 1)
        kl.on('removed', -> evented += 1)

        s.set('e', 5)
        s.set('b.d', 9)

        evented.should.equal(0)
        kl.length.should.equal(4)
        for val, idx in [ 'a', 'b.c', 'b.d', 'e' ]
          kl.at(idx).should.equal(val)

      it 'should handle shadowed all-scope correctly', ->
        s = new Map( a: 1, b: 2 )
        s2 = s.shadow()
        s2.set( c: { d: 3, e: 4 }, f: 5 )

        kl = new KeyList(s2, scope: 'all' )
        kl.length.should.equal(5)
        for val, idx in [ 'c.d', 'c.e', 'f', 'a', 'b' ]
          kl.at(idx).should.equal(val)

        s2.set('g', 6)
        kl.length.should.equal(6)
        for val, idx in [ 'c.d', 'c.e', 'f', 'a', 'b', 'g' ]
          kl.at(idx).should.equal(val)

        s.set('h', 7)
        kl.length.should.equal(7)
        for val, idx in [ 'c.d', 'c.e', 'f', 'a', 'b', 'g', 'h' ]
          kl.at(idx).should.equal(val)

      it 'should handle shadowed direct-scope correctly', ->
        s = new Map( a: 1, b: 2 )
        s2 = s.shadow()
        s2.set( c: { d: 3, e: 4 }, f: 5 )

        kl = new KeyList(s2, scope: 'direct' )
        kl.length.should.equal(3)
        for val, idx in [ 'c.d', 'c.e', 'f' ]
          kl.at(idx).should.equal(val)

        s.set('g', 6)
        kl.length.should.equal(3)
        for val, idx in [ 'c.d', 'c.e', 'f' ]
          kl.at(idx).should.equal(val)

        s2.set('h', 7)
        kl.length.should.equal(4)
        for val, idx in [ 'c.d', 'c.e', 'f', 'h' ]
          kl.at(idx).should.equal(val)

      # values-scope is the default and is already tested above.
      it 'should handle all-include correctly for initial values', ->
        s = new Map( a: 1, b: { c: { d: 2, e: 3 } } )
        kl = new KeyList(s, include: 'all' )

        kl.length.should.equal(5)
        for val, idx in [ 'a', 'b.c.d', 'b.c', 'b', 'b.c.e' ]
          kl.at(idx).should.equal(val)

      it 'should handle all-include correctly for updates', ->
        s = new Map( a: 1, b: { c: { d: 2, e: 3 } } )
        kl = new KeyList(s, include: 'all' )

        s.set('b.c.f.g', 4)
        kl.length.should.equal(7)
        for val, idx in [ 'a', 'b.c.d', 'b.c', 'b', 'b.c.e', 'b.c.f.g', 'b.c.f' ]
          kl.at(idx).should.equal(val)

        s.unset('b.c.d') # check that it _doesn't_ prune what still has branches.
        kl.length.should.equal(6)
        for val, idx in [ 'a', 'b.c', 'b', 'b.c.e', 'b.c.f.g', 'b.c.f' ]
          kl.at(idx).should.equal(val)

        s.unset('b.c.f') # check that it _does_ prune what no longer has branches.
        kl.length.should.equal(4)
        for val, idx in [ 'a', 'b.c', 'b', 'b.c.e' ]
          kl.at(idx).should.equal(val)

    describe 'k/v mapping', ->
      describe 'mapPairs', ->
        it 'should pass k/v pairs into a mapping function', ->
          s = new Map( a: 1, b: 2, c: { d: 3 } )
          kl = new KeyList(s)

          mapped = []
          kl.mapPairs((k, v) -> mapped.push(k, v))
          mapped.should.eql([ 'a', 1, 'b', 2, 'c.d', 3 ])

        it 'should result in a list of mapped results', ->
          s = new Map( a: 1, b: 2, c: { d: 3 } )
          kl = new KeyList(s)

          m = kl.mapPairs((k, v) -> "#{k}: #{v}")
          m.length.should.equal(3)
          for val, idx in [ 'a: 1', 'b: 2', 'c.d: 3' ]
            m.at(idx).should.equal(val)

        it 'should not flatten the result', ->
          s = new Map( a: 1, b: 2, c: { d: 3 } )
          kl = new KeyList(s)

          m = kl.mapPairs((k, v) -> new Varying(v))
          m.length.should.equal(3)
          for idx in [0..2]
            m.at(idx).should.be.an.instanceof(Varying)

        it 'should update if the original value changes', ->
          s = new Map( a: 1, b: 2, c: { d: 3 } )
          kl = new KeyList(s)
          m = kl.mapPairs((k, v) -> "#{k}: #{v}")

          s.set('c.d', 4)
          m.length.should.equal(3)
          for val, idx in [ 'a: 1', 'b: 2', 'c.d: 4' ]
            m.at(idx).should.equal(val)

          s.set('c.e', 8)
          m.length.should.equal(4)
          for val, idx in [ 'a: 1', 'b: 2', 'c.d: 4', 'c.e: 8' ]
            m.at(idx).should.equal(val)

      describe 'flatMapPairs', ->
        it 'should flatten the result', ->
          s = new Map( a: 1, b: 2, c: { d: 3 } )
          kl = new KeyList(s)

          m = kl.flatMapPairs((k, v) -> new Varying("#{k}: #{v}"))
          m.length.should.equal(3)
          for val, idx in [ 'a: 1', 'b: 2', 'c.d: 3' ]
            m.at(idx).should.equal(val)

        it 'should update if the original value or the inner mapping change', ->
          s = new Map( a: 1, b: 2, c: { d: 3 } )
          kl = new KeyList(s)

          x = new Varying(0)
          m = kl.flatMapPairs((k, v) -> x.map((y) -> "#{k}: #{v + y}"))
          m.length.should.equal(3)
          for val, idx in [ 'a: 1', 'b: 2', 'c.d: 3' ]
            m.at(idx).should.equal(val)

          x.set(3)
          m.length.should.equal(3)
          for val, idx in [ 'a: 4', 'b: 5', 'c.d: 6' ]
            m.at(idx).should.equal(val)

          s.set('c.e', 8)
          m.length.should.equal(4)
          for val, idx in [ 'a: 4', 'b: 5', 'c.d: 6', 'c.e: 11' ]
            m.at(idx).should.equal(val)

  describe 'module map get', ->
    it 'returns all keys by default', ->
      s = new Map( a: 1, b: 2, c: { d: { e: 3 }, f: 4 } )
      keys = Enumeration.map.get(s)

      keys.should.eql([ 'a', 'b', 'c.d.e', 'c.f' ])

    it 'returns all branches if include-all', ->
      s = new Map( a: 1, b: 2, c: { d: { e: 3 }, f: 4 } )
      keys = Enumeration.map.get(s, include: 'all' )

      keys.should.eql([ 'a', 'b', 'c', 'c.d', 'c.d.e', 'c.f' ])

    it 'returns shadow-inherited keys by default', ->
      s = new Map( b: 2, c: { d: { e: 3 } } )
      s2 = s.shadow()
      s2.set( a: 1, c: { f: 4 })
      keys = Enumeration.map.get(s2)

      keys.should.eql([ 'a', 'c.f', 'b', 'c.d.e' ])

    it 'returns only direct keys if scope-direct', ->
      s = new Map( b: 2, c: { d: { e: 3 } } )
      s2 = s.shadow()
      s2.set( a: 1, c: { f: 4 })
      keys = Enumeration.map.get(s2, scope: 'direct' )

      keys.should.eql([ 'a', 'c.f' ])

  describe 'module map watch', ->
    it 'returns a KeyList', ->
      s = new Map( a: 1, b: 2, c: { d: { e: 3 }, f: 4 } )
      kl = Enumeration.map.watch(s)
      kl.should.be.an.instanceof(KeyList)
      kl.map.should.equal(s)

    it 'passes options through', ->
      s = new Map( a: 1, b: 2, c: { d: { e: 3 }, f: 4 } )
      kl = Enumeration.map.watch(s, scope: 'direct', include: 'all' )
      kl.scope.should.equal('direct')
      kl.include.should.equal('all')

  describe 'indexlist', ->
    it 'should contain increasing sequential index values', ->
      l = new List(null for _ in [0...10])
      l2 = new IndexList(l)

      l2.length.should.equal(10)
      for idx in [0...10]
        l2.at(idx).should.equal(idx)

    it 'should update to reflect a changing parent list', ->
      l = new List(null for _ in [0...10])
      l2 = new IndexList(l)

      l.removeAt(8)
      l.removeAt(0)
      l.removeAt(2)

      l2.length.should.equal(7)
      for idx in [0...7]
        l2.at(idx).should.equal(idx)

      l.add(null, 0)
      l.add(null, 2)

      l2.length.should.equal(9)
      for idx in [0...9]
        l2.at(idx).should.equal(idx)

    it 'should provide appropriate parameters to mapPairs', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      l2 = new IndexList(l)

      results = []
      l2.mapPairs((k, v) -> results.push(k, v))
      results.should.eql([ 0, 4, 1, 8, 2, 15, 3, 16, 4, 23, 5, 42 ])

    it 'should provide the appropriate mapped result given mapPairs', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      l2 = (new IndexList(l)).mapPairs((k, v) -> k * v)

      l2.length.should.equal(6)
      for value, idx in [ 0, 8, 30, 48, 92, 210 ]
        l2.at(idx).should.equal(value)

    it 'should provide the appropriate mapped result given flatMapPairs', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      x = new Varying(0)
      l2 = (new IndexList(l)).flatMapPairs((k, v) -> x.map((y) -> k + v + y))

      l2.length.should.equal(6)
      for value, idx in [ 4, 9, 17, 19, 27, 47 ]
        l2.at(idx).should.equal(value)

      x.set(2)
      l2.length.should.equal(6)
      for value, idx in [ 6, 11, 19, 21, 29, 49 ]
        l2.at(idx).should.equal(value)

  describe 'module list get', ->
    it 'should return a list of the appropriate length with increasing indices', ->
      Enumeration.list.get(new List(null for _ in [0...10])).should.eql([ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ])

  describe 'module list watch', ->
    it 'should return an IndexList', ->
      Enumeration.list.watch(new List()).should.be.an.instanceof(IndexList)

