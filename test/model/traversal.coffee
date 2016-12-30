should = require('should')

{ Varying } = require('../../lib/core/varying')
{ Struct } = require('../../lib/model/struct')
{ Model } = require('../../lib/model/model')
{ List } = require('../../lib/collection/list')
attribute = require('../../lib/model/attribute')
{ sum } = require('../../lib/collection/folds')
{ Traversal, cases: { recurse, delegate, defer, varying, value, nothing } } = require('../../lib/model/traversal')

describe 'traversal', ->
  describe 'as list', ->
    it 'should provide the appropriate basic arguments', ->
      ss = new Struct( d: 1 )
      s = new Struct( a: 1, b: 2, c: ss )
      results = []
      Traversal.asList(s, (k, v, o) ->
        if v.isStruct is true
          recurse(v)
        else
          results.push(k, v, o)
          nothing
      )
      results.should.eql([ 'a', 1, s, 'b', 2, s, 'd', 1, ss ])

    it 'should process straight value results as a map', ->
      s = new Struct( a: 1, b: 2, c: 3 )
      l = Traversal.asList(s, (k, v) -> value("#{k}#{v}"))

      l.length.should.equal(3)
      for val, idx in [ 'a1', 'b2', 'c3' ]
        l.at(idx).should.equal(val)

    it 'should result in undefined when nothing is passed', ->
      s = new Struct( a: 1, b: 2, c: 3 )
      l = Traversal.asList(s, (k, v) -> if v < 3 then nothing else value(v))

      l.length.should.equal(3)
      for val, idx in [ undefined, undefined, 3 ]
        should(l.at(idx)).equal(val)

    it 'should delegate to another function given delegate', ->
      s = new Struct( a: 1, b: 2, c: 3 )
      l = Traversal.asList(s, (k, v) ->
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
      l = Traversal.asList(s, (k, v) ->
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
      l = Traversal.asList(s, (k, y) -> varying(v.map((x) -> value("#{k}#{y + x}"))))

      l.length.should.equal(3)
      for val, idx in [ 'a1', 'b2', 'c3' ]
        l.at(idx).should.equal(val)

      v.set(2)
      l.length.should.equal(3)
      for val, idx in [ 'a3', 'b4', 'c5' ]
        l.at(idx).should.equal(val)

    it 'should delegate permanently to another function if defer is passed', ->
      s = new Struct( a: 1, b: 2, c: new Struct( d: 3, e: 4 ) )
      l = Traversal.asList(s, (k, v) ->
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
      result = Traversal.asList(s, f, null, sum)

      result.should.be.an.instanceof(Varying)
      result.get().should.equal(10)

    it 'should provide an attribute if available', ->
      class TestModel extends Model
        @attribute('b', attribute.BooleanAttribute)

      results = []
      m = new TestModel( a: 1, b: 2 )
      Traversal.asList(m, (k, v, o, a) -> results.push(k, a))
      results.should.eql([ 'a', undefined, 'b', m.attribute('b') ])

    it 'should pass context through each level', ->
      s = new Struct( a: 1, b: new Struct( c: 2 ), d: 3 )
      context = { con: 'text' }
      results = []
      Traversal.asList(s, ((k, v, _, __, context) ->
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
      Traversal.asList(s, ((k, v, _, __, context) ->
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
      l = Traversal.asList(s, (k, v) ->
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
      l = Traversal.asList(new List([ 1, new Struct( a: 2, b: 3 ), 4 ]), (k, v) ->
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
      Traversal.getArray(s, (k, v, o) ->
        if v.isStruct is true
          recurse(v)
        else
          results.push(k, v, o)
          nothing
      )
      results.should.eql([ 'a', 1, s, 'b', 2, s, 'd', 1, ss ])

    it 'should recurse correctly', ->
      s = new Struct( a: 1, b: new Struct( c: 2, d: 3 ), e: new List([ 4, 5 ]), f: 6 )
      a = Traversal.getArray(s, (k, v, o) ->
        if v.isStruct is true
          recurse(v)
        else
          value("#{k}#{v}")
      )
      a.should.eql([ 'a1', [ 'c2', 'd3' ], [ '04', '15' ], 'f6' ])

    it 'should handle varying results appropriately', ->
      vary = new Varying(2)
      s = new Struct( a: 1, b: 2, c: 3 )
      a = Traversal.getArray(s, (k, v) -> varying(vary.map((x) -> value(v + x))))
      a.should.eql([ 3, 4, 5 ])

  describe 'as natural', ->
    # largely relies on the asList tests for correctness of internal traversal.
    it 'should supply the appropriate parameters', ->
      results = []
      l = new List([ 4, 8 ])
      Traversal.asNatural(l, (k, v, o) ->
        results.push(k, v, o)
        nothing
      )

      class TestModel extends Model
        @attribute('b', attribute.BooleanAttribute)
      m = new TestModel( a: 15, b: 16 )
      Traversal.asNatural(m, (k, v, o, a) ->
        results.push(k, v, o, a)
        nothing
      )

      results.should.eql([ 0, 4, l, 1, 8, l, 'a', 15, m, undefined, 'b', 16, m, m.attribute('b') ])

    it 'should map a list to a list', ->
      l = Traversal.asNatural(new List([ 2, 4, 6, 8, 10 ]), (k, v) -> value(k + v))
      l.length.should.equal(5)
      for val, idx in [ 2, 5, 8, 11, 14 ]
        l.at(idx).should.equal(val)

    it 'should map a struct to a struct', ->
      s = Traversal.asNatural(new Struct( a: 1, b: 2, c: 3 ), (k, v) -> value("#{k}#{v}"))
      s.attributes.should.eql({ a: 'a1', b: 'b2', c: 'c3' })

    it 'should recursively map like types', ->
      source = new Struct( a: 1, b: new List([ 2, new Struct( c: 3, d: 4 ) ]), e: new Struct( f: 5 ) )
      s = Traversal.asNatural(source, (k, v) ->
        if v.isStruct is true
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
      Traversal.getNatural(l, (k, v, o) ->
        results.push(k, v, o)
        nothing
      )

      class TestModel extends Model
        @attribute('b', attribute.BooleanAttribute)
      m = new TestModel( a: 15, b: 16 )
      Traversal.getNatural(m, (k, v, o, a) ->
        results.push(k, v, o, a)
        nothing
      )

      results.should.eql([ 0, 4, l, 1, 8, l, 'a', 15, m, undefined, 'b', 16, m, m.attribute('b') ])

    it 'should map a list to a list', ->
      a = Traversal.getNatural(new List([ 2, 4, 6, 8, 10 ]), (k, v) -> value(k + v))
      a.should.eql([ 2, 5, 8, 11, 14 ])

    it 'should map a struct to a struct', ->
      o = Traversal.getNatural(new Struct( a: 1, b: 2, c: 3 ), (k, v) -> value("#{k}#{v}"))
      o.should.eql({ a: 'a1', b: 'b2', c: 'c3' })

    it 'should recursively map like types', ->
      source = new Struct( a: 1, b: new List([ 2, new Struct( c: 3, d: 4 ) ]), e: new Struct( f: 5 ) )
      o = Traversal.getNatural(source, (k, v) ->
        if v.isStruct is true
          recurse(v)
        else
          value("#{k}#{v}")
      )

      o.should.eql({ a: 'a1', b: [ '02', { c: 'c3', d: 'd4' } ], e: { f: 'f5' } })

