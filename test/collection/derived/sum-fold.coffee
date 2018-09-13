should = require('should')

Varying = require('../../../lib/core/varying').Varying
{ List } = require('../../../lib/collection/list')

describe 'collection', ->
  describe 'sum fold', ->
    it 'should init to the total sum', ->
      (new List([ 0, 4, -2, 3 ])).sum().get().should.equal(5)

      result = null
      (new List([ 1, 8, 0, 9 ])).sum().react((value) -> result = value)
      result.should.equal(18)

    it 'should accept new values', ->
      result = null
      l = new List([ 1, 8, 2, 9 ])
      l.sum().react((value) -> result = value)

      result.should.equal(20)
      l.add(4)
      result.should.equal(24)
      l.add(-3)
      result.should.equal(21)
      l.add(-1)
      result.should.equal(20)
      l.add(0)
      result.should.equal(20)

    it 'should remove old values', ->
      result = null
      l = new List([ 1, 8, 2, 9, -5, 7, -2 ])
      l.sum().react((value) -> result = value)

      result.should.equal(20)
      l.remove(1)
      result.should.equal(19)
      l.remove(-5)
      result.should.equal(24)
      l.remove(-2)
      result.should.equal(26)
      l.remove(9)
      result.should.equal(17)

