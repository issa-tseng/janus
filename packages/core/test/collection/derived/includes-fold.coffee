should = require('should')

{ Varying } = require('../../../lib/core/varying')
{ List } = require('../../../lib/collection/list')
{ IncludesFold } = require('../../../lib/collection/derived/includes-fold')
{ includes } = IncludesFold

describe 'collection', ->
  describe 'includes fold', ->
    it 'should return a varying initially set to the appropriate index value', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      includes(l, 0).isVarying.should.equal(true)

      includes(l, 4).get().should.equal(true)
      includes(l, 5).get().should.equal(false)

      result = null
      v = includes(l, 8)
      v.react((x) -> result = x)
      result.should.equal(true)

    it 'should become true if a matching member is added', ->
      l = new List()

      result = null
      includes(l, 'hello').react((value) -> result = value)
      result.should.equal(false)

      l.add('hello')
      result.should.equal(true)

    it 'should become false if the only matching member is removed', ->
      l = new List([ 'hi', 'hello' ])

      result = null
      includes(l, 'hello').react((value) -> result = value)
      result.should.equal(true)

      l.remove('hello')
      result.should.equal(false)

    it 'should account for multiple instances', ->
      l = new List([ 'abc', 'hello', 'hello', 'def', 'hello' ])

      result = null
      includes(l, 'hello').react((value) -> result = value)
      result.should.equal(true)

      l.remove('hello')
      result.should.equal(true)
      l.remove('hello')
      result.should.equal(true)
      l.remove('hello')
      result.should.equal(false)

      l.add('hello')
      result.should.equal(true)
      l.add('hello')
      result.should.equal(true)
      l.remove('hello')
      result.should.equal(true)
      l.remove('hello')
      result.should.equal(false)

    it 'should handle a changing search value', ->
      l = new List([ 'hi', 'hello', 'hello', 'hi', 'hi', 'hello' ])

      v = new Varying('hello')
      result = null
      includes(l, v).react((value) -> result = value)
      result.should.equal(true)

      v.set('abc')
      result.should.equal(false)
      v.set('hi')
      result.should.equal(true)
      l.remove('hi')
      result.should.equal(true)
      l.remove('hi')
      result.should.equal(true)
      l.remove('hi')
      result.should.equal(false)
      v.set('hello')
      result.should.equal(true)

    it 'should cease reacting on the target object Varying upon its own destruction', ->
      # also tests that the managed Varying handles the Base object correctly.
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      target = new Varying(15)

      v = includes(l, target)
      o = v.react(->)

      target.refCount().get().should.equal(1)
      o.stop()
      target.refCount().get().should.equal(0)

