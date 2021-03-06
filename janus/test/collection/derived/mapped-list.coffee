should = require('should')

{ Varying } = require('../../../lib/core/varying')
{ List } = require('../../../lib/collection/list')

describe 'collection', ->
  describe 'mapped list', ->
    it 'should populate initially with appropriate values', ->
      l = (new List([ 1, 2, 3 ])).map((x) -> 2 * x)
      l.length_.should.equal(3)
      l.at_(0).should.equal(2)
      l.at_(1).should.equal(4)
      l.at_(2).should.equal(6)

    it 'should map additional incoming values', ->
      l = new List([ 1, 2, 3 ])
      m = l.map((x) -> 2 * x)

      l.add(4)
      m.length_.should.equal(4)
      m.at_(3).should.equal(8)

      l.add(5, 1)
      m.length_.should.equal(5)
      m.at_(1).should.equal(10)

    it 'should map undefined results', -> # gh156
      l = new List([ new Varying(0) ])
      l2 = l.flatMap((x) -> x)
      l.at_(0).set(undefined)
      (l2.at_(0) is undefined).should.equal(true)

    it 'should map array values', -> # gh163
      l = new List([ 0, 1, 2 ])
      l2 = l.flatMap((x) -> [ x, -x ])

      l2.length_.should.equal(3)
      l2.at_(0).should.eql([ 0, -0 ])
      l2.at_(1).should.eql([ 1, -1 ])
      l2.at_(2).should.eql([ 2, -2 ])

    it 'should remove the correct values', ->
      l = new List([ 1, 2, 3 ])
      m = l.map((x) -> 2 * x)

      l.remove(2)
      m.list.should.eql([ 2, 6 ])

      l.removeAt(0)
      m.list.should.eql([ 6 ])

    it 'should move the correct values', ->
      l = new List([ 1, 2, 3 ])
      m = l.map((x) -> 2 * x)

      l.move(2, 0)
      for elem, idx in [ 4, 2, 6 ]
        m.at_(idx).should.equal(elem)

    it 'should not map the wrong value given length reaction side effects', ->
      l = new List([ 1 ])
      l2 = l.map((x) -> x + 100)
      l.length.react((len) -> l.add(0) if len is 0)
      l.removeAt(0)
      l2.list.should.eql([ 100 ])

  describe 'flatMapped list', ->
    it 'should populate initially with appropriate values', ->
      v = new Varying(2)
      l = (new List([ 1, 2, 3 ])).flatMap((x) -> v.map((y) -> x * y))
      l.length_.should.equal(3)
      l.at_(0).should.equal(2)
      l.at_(1).should.equal(4)
      l.at_(2).should.equal(6)

    it 'should react appropriately if an inner Varying changes', ->
      v = new Varying(2)
      l = (new List([ 1, 2, 3 ])).flatMap((x) -> v.map((y) -> x * y))
      l.list.should.eql([ 2, 4, 6 ])

      v.set(3)
      l.length_.should.equal(3)
      l.at_(0).should.equal(3)
      l.at_(1).should.equal(6)
      l.at_(2).should.equal(9)

    it 'should add and react correctly to new values', ->
      v = new Varying(2)
      l = new List([ 1, 2, 3 ])
      m = l.flatMap((x) -> v.map((y) -> x * y))

      l.add(4)
      m.length_.should.equal(4)
      m.at_(3).should.equal(8)

      l.add(5, 1)
      m.length_.should.equal(5)
      m.at_(1).should.equal(10)

      v.set(3)
      m.list.should.eql([ 3, 15, 6, 9, 12 ])

    it 'should remove the correct values', ->
      v = new Varying(2)
      l = new List([ 1, 2, 3, 4 ])
      m = l.flatMap((x) -> v.map((y) -> x * y))

      l.remove(3)
      m.list.should.eql([ 2, 4, 8 ])

      l.removeAt(1)
      m.list.should.eql([ 2, 8 ])

      v.set(3)
      m.list.should.eql([ 3, 12 ])

    it 'should move the correct values and mappers', ->
      v = new Varying(2)
      l = new List([ 1, 2, 3, 4 ])
      m = l.flatMap((x) -> v.map((y) -> x * y))

      l.move(3, 1)
      m.list.should.eql([ 2, 6, 4, 8 ])

      v.set(3)
      m.list.should.eql([ 3, 9, 6, 12 ])

    it 'should stop Varieds related to removed items', ->
      calledWith = []

      v = new Varying(2)
      l = new List([ 1, 2, 3, 4 ])
      m = l.flatMap((x) -> v.map((y) -> calledWith.push(x); x * y))

      l.remove(3)

      calledWith = []
      v.set(3)
      calledWith.should.eql([ 1, 2, 4 ])

