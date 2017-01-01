should = require('should')

Model = require('../../../lib/model/model').Model

Varying = require('../../../lib/core/varying').Varying
{ List } = require('../../../lib/collection/list')

describe 'collection', ->
  describe 'catted list', ->
    it 'should return a new list composed of two component lists', ->
      l = (new List([ 1, 2 ])).concat(new List([ 3, 4 ]))
      l.length.should.equal(4)
      for elem, idx in [ 1, 2, 3, 4 ]
        l.at(idx).should.equal(elem)

    it 'should return a new list composed of more than two component lists', ->
      l = (new List([ 1, 2 ])).concat(new List([ 3, 4 ]), new List([ 5, 6 ]), new List([ 7, 8 ]))
      l.length.should.equal(8)
      for elem, idx in [ 1, 2, 3, 4, 5, 6, 7, 8 ]
        l.at(idx).should.equal(elem)

    it 'should update when an element is added to a component list', ->
      sl1 = new List([ 1, 2 ])
      sl2 = new List([ 3, 4 ])
      sl3 = new List([ 5, 6 ])
      cl = sl1.concat(sl2, sl3)

      sl1.add(2.5)
      cl.length.should.equal(7)
      for elem, idx in [ 1, 2, 2.5, 3, 4, 5, 6 ]
        cl.at(idx).should.equal(elem)

      sl2.add(2.9, 0)
      cl.length.should.equal(8)
      for elem, idx in [ 1, 2, 2.5, 2.9, 3, 4, 5, 6 ]
        cl.at(idx).should.equal(elem)

      sl3.add(5.5, 1)
      cl.length.should.equal(9)
      for elem, idx in [ 1, 2, 2.5, 2.9, 3, 4, 5, 5.5, 6 ]
        cl.at(idx).should.equal(elem)

    it 'should update when an element is removed from a component list', ->
      sl1 = new List([ 1 ])
      sl2 = new List([ 2, 3 ])
      cl = sl1.concat(sl2)

      sl2.removeAt(0)
      cl.length.should.equal(2)
      for elem, idx in [ 1, 3 ]
        cl.at(idx).should.equal(elem)

      sl1.removeAt(0)
      cl.length.should.equal(1)
      cl.at(0).should.equal(3)

    it 'should update when an element is moved within a component list', ->
      sl1 = new List([ 1, 2 ])
      sl2 = new List([ 3, 4, 5 ])
      cl = sl1.concat(sl2)

      sl2.move(3, 1)
      cl.length.should.equal(5)
      for elem, idx in [ 1, 2, 4, 3, 5 ]
        cl.at(idx).should.equal(elem)

