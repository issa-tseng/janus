should = require('should')

Model = require('../../../lib/model/model').Model

Varying = require('../../../lib/core/varying').Varying
{ List } = require('../../../lib/collection/list')
{ IndexOfFold } = require('../../../lib/collection/derived/indexof-fold')
{ indexOf } = IndexOfFold

describe 'collection', ->
  describe 'indexof fold', ->
    it 'should return a varying initially set to the appropriate index value', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      indexOf(l, 8).isVarying.should.equal(true)

      indexOf(l, 8).get().should.equal(1)
      indexOf(l, 16).get().should.equal(3)

      result = null
      v = indexOf(l, 23)
      v.react((x) -> result = x)
      result.should.equal(4)

    it 'should return -1 if the value is not found', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      indexOf(l, 12).get().should.equal(-1)

    it 'should update the index when values are inserted', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])

      result = null
      v = indexOf(l, 48)
      v.react((x) -> result = x)
      result.should.equal(-1)

      l.add(45)
      result.should.equal(-1)
      l.add(48)
      result.should.equal(7)
      l.add(52)
      result.should.equal(7)
      l.add(0, 0)
      result.should.equal(8)
      l.add(46, 8)
      result.should.equal(9)
      l.add(48)
      result.should.equal(9)

    it 'should update the index when values are removed', ->
      l = new List([ 4, 8, 15, 16, 23, 42, 16 ])

      result = null
      v = indexOf(l, 16)
      v.react((x) -> result = x)
      result.should.equal(3)

      l.removeAt(2)
      result.should.equal(2)
      l.removeAt(4)
      result.should.equal(2)
      l.removeAt(2)
      result.should.equal(3)
      l.removeAt(3)
      result.should.equal(-1)

    it 'should update the index when values are moved', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])

      result = null
      v = indexOf(l, 16)
      v.react((x) -> result = x)
      result.should.equal(3)

      l.moveAt(0, 2)
      result.should.equal(3)
      l.moveAt(5, 0)
      result.should.equal(4)
      l.moveAt(5, 4)
      result.should.equal(5)
      l.moveAt(5, 2)
      result.should.equal(2)
      l.moveAt(5, 2)
      result.should.equal(3)
      l.moveAt(0, 4)
      result.should.equal(2)

    it 'should accept a Varying target object', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      target = new Varying(15)

      result = null
      v = indexOf(l, target)
      v.react((x) -> result = x)
      result.should.equal(2)

      target.set(23)
      result.should.equal(4)
      l.remove(8)
      result.should.equal(3)
      target.set(0)
      result.should.equal(-1)

    it 'should cease reacting on the target object Varying upon its own destruction', ->
      # also tests that the managed Varying handles the Base object correctly.
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      target = new Varying(15)

      v = indexOf(l, target)
      o = v.react(->)

      target.refCount().get().should.equal(1)
      o.stop()
      target.refCount().get().should.equal(0)

