should = require('should')

{ Struct } = require('../../lib/model/struct')
{ KeyList, Enumeration } = require('../../lib/model/enumeration')

describe 'struct enumeration', ->
  describe 'keylist', ->
    describe 'key tracking', ->
      it 'should include all initial keys', ->
        s = new Struct( a: 1, b: 2, c: 3 )
        kl = new KeyList(s)

        kl.length.should.equal(3)
        for val, idx in [ 'a', 'b', 'c' ]
          kl.at(idx).should.equal(val)

      it 'should include all initial nested value keys', ->
        s = new Struct( a: 1, b: 2, c: { d: 3, e: { f: 4 } } )
        kl = new KeyList(s)

        kl.length.should.equal(4)
        for val, idx in [ 'a', 'b', 'c.d', 'c.e.f' ]
          kl.at(idx).should.equal(val)

      it 'should update to reflect new keys', ->
        s = new Struct( a: 1, b: { c: 2, d: 3 } )
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
        s = new Struct( a: 1, b: { c: 2, d: 3 }, e: 4 )
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
        s = new Struct( a: 1, b: { c: 2, d: 3 }, e: 4 )
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
        s = new Struct( a: 1, b: 2 )
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
        s = new Struct( a: 1, b: 2 )
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
        s = new Struct( a: 1, b: { c: { d: 2, e: 3 } } )
        kl = new KeyList(s, include: 'all' )

        kl.length.should.equal(5)
        for val, idx in [ 'a', 'b.c.d', 'b.c', 'b', 'b.c.e' ]
          kl.at(idx).should.equal(val)

      it 'should handle all-include correctly for updates', ->
        s = new Struct( a: 1, b: { c: { d: 2, e: 3 } } )
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
        console.log(kl.list)
        kl.length.should.equal(4)
        for val, idx in [ 'a', 'b.c', 'b', 'b.c.e' ]
          kl.at(idx).should.equal(val)

