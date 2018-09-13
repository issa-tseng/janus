should = require('should')

Model = require('../../../lib/model/model').Model

Varying = require('../../../lib/core/varying').Varying
{ List } = require('../../../lib/collection/list')
{ MinMaxFold } = require('../../../lib/collection/derived/min-max-fold')
{ min, max } = MinMaxFold

describe 'collection', ->
  describe 'min fold', ->
    it 'should init to the minimum value', ->
      (new List([ 0, 4, -2, 3 ])).min().get().should.equal(-2)

      result = null
      (new List([ 1, 8, 0, 9 ])).min().react((value) -> result = value)
      result.should.equal(0)

    it 'should accept new smaller values', ->
      result = null
      l = new List([ 1, 8, 2, 9 ])
      l.min().react((value) -> result = value)

      result.should.equal(1)
      l.add(4)
      result.should.equal(1)
      l.add(0)
      result.should.equal(0)
      l.add(-3)
      result.should.equal(-3)
      l.add(1)
      result.should.equal(-3)

    it 'should find the next-smallest value when the smallest is lost', ->
      result = null
      l = new List([ 1, 8, 2, 9 ])
      l.min().react((value) -> result = value)

      l.add(1)
      result.should.equal(1)
      l.remove(1)
      result.should.equal(1)
      l.remove(1)
      result.should.equal(2)
      l.remove(2)
      result.should.equal(8)

  describe 'max fold', ->
    it 'should init to the maximum value', ->
      (new List([ 0, 4, -2, 3 ])).max().get().should.equal(4)

      result = null
      (new List([ 1, 8, 0, 9 ])).max().react((value) -> result = value)
      result.should.equal(9)

    it 'should accept new larger values', ->
      result = null
      l = new List([ 1, 8, 2, 9 ])
      l.max().react((value) -> result = value)

      result.should.equal(9)
      l.add(4)
      result.should.equal(9)
      l.add(10)
      result.should.equal(10)
      l.add(13)
      result.should.equal(13)
      l.add(1)
      result.should.equal(13)

    it 'should find the next-largest value when the largest is lost', ->
      result = null
      l = new List([ 1, 8, 2, 9 ])
      l.max().react((value) -> result = value)

      l.add(9)
      result.should.equal(9)
      l.remove(9)
      result.should.equal(9)
      l.remove(9)
      result.should.equal(8)
      l.remove(8)
      result.should.equal(2)

