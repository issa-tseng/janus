should = require('should')

{ Varying } = require('../../lib/core/varying')
{ Struct } = require('../../lib/collection/struct')
{ Model } = require('../../lib/model/model')
{ List } = require('../../lib/collection/list')
attribute = require('../../lib/model/attribute')
{ sum } = require('../../lib/collection/folds')
{ Traversal } = require('../../lib/collection/traversal')
{ recurse, delegate, defer, varying, value, nothing } = Traversal.cases

# util
shadowWith = (s, obj) ->
  s2 = s.shadow()
  s2.set(obj)
  s2

# TODO: ensure that updates to source data propagates as expected.
# (it really ought to given we're built on top of enumeration, in which this is tested).

describe 'traversal', ->
  describe 'as list', ->
    it 'should provide the appropriate basic arguments', ->
      ss = new Struct( d: 1 )
      s = new Struct( a: 1, b: 2, c: ss )
      results = []
      Traversal.asList(s, map: (k, v, o) ->
        if v.isStruct is true
          recurse(v)
        else
          results.push(k, v, o)
          nothing
      )
      results.should.eql([ 'a', 1, s, 'b', 2, s, 'd', 1, ss ])

    it 'should process straight value results as a map', ->
      s = new Struct( a: 1, b: 2, c: 3 )
      l = Traversal.asList(s, map: (k, v) -> value("#{k}#{v}"))

      l.length.should.equal(3)
      for val, idx in [ 'a1', 'b2', 'c3' ]
        l.at(idx).should.equal(val)

    it 'should result in undefined when nothing is passed', ->
      s = new Struct( a: 1, b: 2, c: 3 )
      l = Traversal.asList(s, map: (k, v) -> if v < 3 then nothing else value(v))

      l.length.should.equal(3)
      for val, idx in [ undefined, undefined, 3 ]
        should(l.at(idx)).equal(val)

    it 'should delegate to another function given delegate', ->
      s = new Struct( a: 1, b: 2, c: 3 )
      l = Traversal.asList(s, map: (k, v) ->
        if v < 3
          delegate((k, v) -> if v < 2 then value('x') else value('y'))
        else
          value(v)
      )

      l.length.should.equal(3)
      for val, idx in [ 'x', 'y', 3 ]
        l.at(idx).should.equal(val)

    it 'should recurse into subobjects if requested', ->
      s = new Struct( a: 1, b: 2, c: new Struct( d: 3, e: 4 ) )
      l = Traversal.asList(s, map: (k, v) ->
        if v.isStruct is true
          recurse(v)
        else
          value("#{k}#{v}")
      )

      l.length.should.equal(3)
      for val, idx in [ 'a1', 'b2' ]
        l.at(idx).should.equal(val)

      ll = l.at(2)
      ll.length.should.equal(2)
      for val, idx in [ 'd3', 'e4' ]
        ll.at(idx).should.equal(val)

    it 'should use a varying if passed', ->
      s = new Struct( a: 1, b: 2, c: 3 )
      v = new Varying(0)
      l = Traversal.asList(s, map: (k, y) -> varying(v.map((x) -> value("#{k}#{y + x}"))))

      l.length.should.equal(3)
      for val, idx in [ 'a1', 'b2', 'c3' ]
        l.at(idx).should.equal(val)

      v.set(2)
      l.length.should.equal(3)
      for val, idx in [ 'a3', 'b4', 'c5' ]
        l.at(idx).should.equal(val)

    it 'should delegate permanently to another function if defer is passed', ->
      s = new Struct( a: 1, b: 2, c: new Struct( d: 3, e: 4 ) )
      l = Traversal.asList(s, map: (k, v) ->
        if v.isStruct is true
          defer((k, v) ->
            if v.isStruct is true
              recurse(v)
            else
              value("#{k}#{v}!")
          )
        else
          value("#{k}#{v}")
      )

      l.length.should.equal(3)
      for val, idx in [ 'a1', 'b2' ]
        l.at(idx).should.equal(val)

      ll = l.at(2)
      ll.length.should.equal(2)
      for val, idx in [ 'd3!', 'e4!' ]
        ll.at(idx).should.equal(val)

    it 'should reduce with the given function if given', ->
      s = new Struct( a: 1, b: 2, c: new Struct( d: 3, e: 4 ) )
      f = (_, v) ->
        if v.isStruct is true
          recurse(v)
        else
          value(v)
      result = Traversal.asList(s, { map: f, reduce: sum }, null)

      result.should.be.an.instanceof(Varying)
      result.get().should.equal(10)

    it 'should provide an attribute if available', ->
      class TestModel extends Model
        @attribute('b', attribute.BooleanAttribute)

      results = []
      m = new TestModel( a: 1, b: 2 )
      Traversal.asList(m, map: (k, v, o, a) -> results.push(k, a))
      results.should.eql([ 'a', undefined, 'b', m.attribute('b') ])

    it 'should pass context through each level', ->
      s = new Struct( a: 1, b: new Struct( c: 2 ), d: 3 )
      context = { con: 'text' }
      results = []
      Traversal.asList(s, (map: (k, v, _, __, context) ->
        if v.isStruct is true
          recurse(v)
        else
          results.push(context)
          nothing
      ), context)

      results.should.eql([ context, context, context ])

    it 'should accept context as the second case parameter', ->
      s = new Struct( a: 1, b: new Struct( c: 2 ), d: 3 )
      context = { z: 0 }
      results = []
      Traversal.asList(s, (map: (k, v, _, __, context) ->
        if v.isStruct is true
          recurse(v, z: 1 )
        else if k is 'd'
          delegate(((k, v, _, __, context) -> results.push(context); nothing), z: 2 )
        else
          results.push(context)
          nothing
      ), context)

      results.should.eql([ { z: 0 }, { z: 1 }, { z: 2 } ])

    it 'should work with nested lists', ->
      s = new Struct( a: 1, b: new List([ 2, 3 ]), d: 4 )
      l = Traversal.asList(s, map: (k, v) ->
        if v.isCollection is true
          recurse(v)
        else
          value("#{k}#{v}")
      )

      l.length.should.equal(3)
      l.at(0).should.equal('a1')
      ll = l.at(1)
      ll.length.should.equal(2)
      ll.at(0).should.equal('02', '13')
      l.at(2).should.equal('d4')

    it 'should work with root lists', ->
      l = Traversal.asList(new List([ 1, new Struct( a: 2, b: 3 ), 4 ]), map: (k, v) ->
        if v.isStruct is true
          recurse(v)
        else
          value("#{k}#{v}")
      )

      l.length.should.equal(3)
      l.at(0).should.equal('01')
      ll = l.at(1)
      ll.length.should.equal(2)
      ll.at(0).should.equal('a2')
      ll.at(1).should.equal('b3')
      l.at(2).should.equal('24')

  describe 'get array', ->
    # largely relies on the asList tests for correctness of internal traversal.
    it 'should supply the appropriate basic parameters', ->
      ss = new Struct( d: 1 )
      s = new Struct( a: 1, b: 2, c: ss )
      results = []
      Traversal.getArray(s, map: (k, v, o) ->
        if v.isStruct is true
          recurse(v)
        else
          results.push(k, v, o)
          nothing
      )
      results.should.eql([ 'a', 1, s, 'b', 2, s, 'd', 1, ss ])

    it 'should recurse correctly', ->
      s = new Struct( a: 1, b: new Struct( c: 2, d: 3 ), e: new List([ 4, 5 ]), f: 6 )
      a = Traversal.getArray(s, map: (k, v, o) ->
        if v.isEnumerable is true
          recurse(v)
        else
          value("#{k}#{v}")
      )
      a.should.eql([ 'a1', [ 'c2', 'd3' ], [ '04', '15' ], 'f6' ])

    it 'should handle varying results appropriately', ->
      vary = new Varying(2)
      s = new Struct( a: 1, b: 2, c: 3 )
      a = Traversal.getArray(s, map: (k, v) -> varying(vary.map((x) -> value(v + x))))
      a.should.eql([ 3, 4, 5 ])

  describe 'as natural', ->
    # largely relies on the asList tests for correctness of internal traversal.
    it 'should supply the appropriate parameters', ->
      results = []
      l = new List([ 4, 8 ])
      Traversal.asNatural(l, map: (k, v, o) ->
        results.push(k, v, o)
        nothing
      )

      class TestModel extends Model
        @attribute('b', attribute.BooleanAttribute)
      m = new TestModel( a: 15, b: 16 )
      Traversal.asNatural(m, map: (k, v, o, a) ->
        results.push(k, v, o, a)
        nothing
      )

      results.should.eql([ 0, 4, l, 1, 8, l, 'a', 15, m, undefined, 'b', 16, m, m.attribute('b') ])

    it 'should map a list to a list', ->
      l = Traversal.asNatural(new List([ 2, 4, 6, 8, 10 ]), map: (k, v) -> value(k + v))
      l.length.should.equal(5)
      for val, idx in [ 2, 5, 8, 11, 14 ]
        l.at(idx).should.equal(val)

    it 'should map a struct to a struct', ->
      s = Traversal.asNatural(new Struct( a: 1, b: 2, c: 3 ), map: (k, v) -> value("#{k}#{v}"))
      s.attributes.should.eql({ a: 'a1', b: 'b2', c: 'c3' })

    it 'should recursively map like types', ->
      source = new Struct( a: 1, b: new List([ 2, new Struct( c: 3, d: 4 ) ]), e: new Struct( f: 5 ) )
      s = Traversal.asNatural(source, map: (k, v) ->
        if v.isEnumerable is true
          recurse(v)
        else
          value("#{k}#{v}")
      )

      s.should.be.an.instanceof(Struct)
      s.get('a').should.equal('a1')
      s.get('b').should.be.an.instanceof(List)
      s.get('e').should.be.an.instanceof(Struct)

      s.get('b').length.should.equal(2)
      s.get('b').at(0).should.equal('02')
      s.get('b').at(1).should.be.an.instanceof(Struct)

      s.get('b').at(1).attributes.should.eql({ c: 'c3', d: 'd4' })

      s.get('e').attributes.should.eql({ f: 'f5' })

  describe 'get natural', ->
    # largely relies on the asList tests for correctness of internal traversal.
    it 'should supply the appropriate parameters', ->
      results = []
      l = new List([ 4, 8 ])
      Traversal.getNatural(l, map: (k, v, o) ->
        results.push(k, v, o)
        nothing
      )

      class TestModel extends Model
        @attribute('b', attribute.BooleanAttribute)
      m = new TestModel( a: 15, b: 16 )
      Traversal.getNatural(m, map: (k, v, o, a) ->
        results.push(k, v, o, a)
        nothing
      )

      results.should.eql([ 0, 4, l, 1, 8, l, 'a', 15, m, undefined, 'b', 16, m, m.attribute('b') ])

    it 'should map a list to a list', ->
      a = Traversal.getNatural(new List([ 2, 4, 6, 8, 10 ]), map: (k, v) -> value(k + v))
      a.should.eql([ 2, 5, 8, 11, 14 ])

    it 'should map a struct to a struct', ->
      o = Traversal.getNatural(new Struct( a: 1, b: 2, c: 3 ), map: (k, v) -> value("#{k}#{v}"))
      o.should.eql({ a: 'a1', b: 'b2', c: 'c3' })

    it 'should recursively map like types', ->
      source = new Struct( a: 1, b: new List([ 2, new Struct( c: 3, d: 4 ) ]), e: new Struct( f: 5 ) )
      o = Traversal.getNatural(source, map: (k, v) ->
        if v.isEnumerable is true
          recurse(v)
        else
          value("#{k}#{v}")
      )

      o.should.eql({ a: 'a1', b: [ '02', { c: 'c3', d: 'd4' } ], e: { f: 'f5' } })

  describe 'default implementations', ->
    describe 'serialization', ->
      it 'should return an object with shallow keys intact', ->
        o = (new Struct( a: 1, b: 2, c: 3 )).serialize()
        o.should.eql({ a: 1, b: 2, c: 3 })

      it 'should return an array with values intact', ->
        a = (new List([ 4, 8, 15, 16, 23, 42 ])).serialize()
        a.should.eql([ 4, 8, 15, 16, 23, 42 ])

      it 'should handle nested structures appropriately', ->
        o = (new Struct( a: 1, b: new List([ 2, new Struct( c: 3, d: 4 ) ]), e: new Struct( f: 5 ) )).serialize()
        o.should.eql({ a: 1, b: [ 2, { c: 3, d: 4 } ], e: { f: 5 } })

      it 'should rely on attribute serialization methods when available', ->
        class TestModel extends Model
          @attribute('b', class extends attribute.NumberAttribute
            serialize: -> "number: #{this.getValue()}"
          )

          @attribute('c', class extends attribute.Attribute
            serialize: -> JSON.stringify(this.getValue())
          )

        o = (new TestModel( a: 1, b: 2, c: [ 3, 4, 5 ] )).serialize()
        o.should.eql({ a: 1, b: 'number: 2', c: '[3,4,5]' })

    describe 'diff', ->
      it 'should consider unlike objects eternally different', ->
        (new List()).watchDiff(new Struct()).get().should.equal(true)
        (new Struct()).watchDiff(new List()).get().should.equal(true)
        (new Struct()).watchDiff(true).get().should.equal(true)
        (new Struct()).watchDiff().get().should.equal(true)

      it 'should diff shallow values in structs', ->
        sa = new Struct( a: 1, b: 2, c: { d: 3 } )
        sb = new Struct( a: 1, b: 2, c: { d: 3 } )

        result = null
        sa.watchDiff(sb).reactNow((x) -> result = x)

        result.should.equal(false)
        sa.set('b', 3)
        result.should.equal(true)
        sb.set('b', 3)
        result.should.equal(false)
        sb.unset('c')
        result.should.equal(true)
        sb.set('c', { d: 3 })
        result.should.equal(false)

      it 'should diff shallow values in lists', ->
        la = new List([ 1, 2, 3, 4, 5 ])
        lb = new List([ 1, 2, 3, 4, 5 ])

        result = null
        la.watchDiff(lb).reactNow((x) -> result = x)

        result.should.equal(false)
        la.add(6)
        result.should.equal(true)
        lb.add(6)
        result.should.equal(false)
        la.removeAt(0)
        result.should.equal(true)
        lb.putAll([ 2, 3, 4, 5, 6 ])
        result.should.equal(false)

      it 'should diff structs nested in structs correctly', ->
        sa = new Struct( a: 1, b: 2, c: new Struct( d: 3 ) )
        sb = new Struct( a: 1, b: 2, c: new Struct( d: 3 ) )

        result = null
        sa.watchDiff(sb).reactNow((x) -> result = x)

        result.should.equal(false)
        sb.set('c', new Struct( d: 3 ))
        result.should.equal(false)
        sb.get('c').set('e', 4)
        result.should.equal(true)
        sa.get('c').set('e', 4)
        result.should.equal(false)
        sa.unset('c')
        result.should.equal(true)

      it 'should diff lists nested in structs correctly', ->
        sa = new Struct( a: 1, b: 2, c: new List([ 3, 4 ]) )
        sb = new Struct( a: 1, b: 2, c: new List([ 3, 4 ]) )

        result = null
        sa.watchDiff(sb).reactNow((x) -> result = x)

        result.should.equal(false)
        sb.set('c', new List([ 3, 4 ]))
        result.should.equal(false)
        sb.get('c').add(5)
        result.should.equal(true)
        sa.get('c').add(5)
        result.should.equal(false)
        sa.get('c').put(0, 0)
        result.should.equal(true)
        sa.unset('c')
        result.should.equal(true)

      it 'should diff lists nested in lists correctly', ->
        la = new List([ 1, new List([ 2, 3 ]), 4 ])
        lb = new List([ 1, new List([ 2, 3 ]), 4 ])

        result = null
        la.watchDiff(lb).reactNow((x) -> result = x)

        result.should.equal(false)
        la.at(1).add(0)
        result.should.equal(true)
        lb.at(1).add(0)
        result.should.equal(false)
        lb.put(new List([ 2, 3, 0 ]), 1)
        result.should.equal(false)
        la.removeAt(1)
        result.should.equal(true)

      it 'should diff structs nested in lists correctly', ->
        la = new List([ 1, new Struct( a: 2, b: 3 ), 4 ])
        lb = new List([ 1, new Struct( a: 2, b: 3 ), 4 ])

        result = null
        la.watchDiff(lb).reactNow((x) -> result = x)

        result.should.equal(false)
        la.at(1).set( c: 4 )
        result.should.equal(true)
        lb.at(1).set( c: 4 )
        result.should.equal(false)
        lb.put(new Struct( a: 2, b: 3, c: 4 ), 1)
        result.should.equal(false)
        la.removeAt(1)
        result.should.equal(true)
