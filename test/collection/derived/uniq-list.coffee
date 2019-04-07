should = require('should')

{ Model } = require('../../../lib/model/model')
{ List } = require('../../../lib/collection/list')

describe 'collection', ->
  describe 'uniq list', ->
    # in general these tests must ensure both that the operation succeeded and that
    # the index cache is appropriately updated for following operations.

    it 'should return a new list with duplicates omitted', ->
      l = (new List([ 1, 2, 3, 3, 4, 2 ])).uniq()
      l.length_.should.equal(4)
      for elem, idx in [ 1, 2, 3, 4 ]
        l.at_(idx).should.equal(elem)

    it 'should handle added extant elements', ->
      ol = new List([ 1, 2, 3, 3, 4, 2 ])
      ul = ol.uniq()
      ol.add(1)
      ul.length_.should.equal(4)

    it 'should handle added new new elements', ->
      ol = new List([ 1, 2, 3, 3, 4, 2 ])
      ul = ol.uniq()

      ol.add(5)
      ul.length_.should.equal(5)
      for elem, idx in [ 1, 2, 3, 4, 5 ]
        ul.at_(idx).should.equal(elem)

      ol.add(6, 2)
      ul.length_.should.equal(6)
      for elem, idx in [ 1, 2, 6, 3, 4, 5 ]
        ul.at_(idx).should.equal(elem)

    it 'should handle added earlier new elements', ->
      ol = new List([ 1, 2, 3, 3, 4, 2 ])
      ul = ol.uniq()

      ol.add(4, 0)
      ul.length_.should.equal(4)
      for elem, idx in [ 4, 1, 2, 3 ]
        ul.at_(idx).should.equal(elem)

      ol.add(2, 1)
      ul.length_.should.equal(4)
      for elem, idx in [ 4, 2, 1, 3 ]
        ul.at_(idx).should.equal(elem)

    it 'should handle removed unique elements', ->
      ol = new List([ 1, 2, 3, 3, 4, 2 ])
      ul = ol.uniq()

      ol.remove(1)
      ul.length_.should.equal(3)
      for elem, idx in [ 2, 3, 4 ]
        ul.at_(idx).should.equal(elem)

      ol.remove(4)
      ul.length_.should.equal(2)
      for elem, idx in [ 2, 3 ]
        ul.at_(idx).should.equal(elem)

    it 'should handle removed duplicate tail elements', ->
      ol = new List([ 1, 2, 3, 3, 4, 2 ])
      ul = ol.uniq()

      ol.removeAt(-1)
      ul.length_.should.equal(4)
      for elem, idx in [ 1, 2, 3, 4 ]
        ul.at_(idx).should.equal(elem)

      ol.removeAt(1)
      ul.length_.should.equal(3)
      for elem, idx in [ 1, 3, 4 ]
        ul.at_(idx).should.equal(elem)

    it 'should handle removed duplicate head elements', ->
      ol = new List([ 1, 2, 3, 3, 4, 2, 3 ])
      ul = ol.uniq()

      ol.removeAt(1)
      ul.length_.should.equal(4)
      for elem, idx in [ 1, 3, 4, 2 ]
        ul.at_(idx).should.equal(elem)

      ol.removeAt(1)
      ol.removeAt(1)
      ul.length_.should.equal(4)
      for elem, idx in [ 1, 4, 2, 3 ]
        ul.at_(idx).should.equal(elem)

    it 'should handle nonduplicate moves', ->
      ol = new List([ 1, 2, 3, 3, 4, 2, 3 ])
      ul = ol.uniq()

      ol.moveAt(0, 2)
      ul.length_.should.equal(4)
      for elem, idx in [ 2, 3, 1, 4 ]
        ul.at_(idx).should.equal(elem)

      ol.moveAt(2, 1)
      ul.length_.should.equal(4)
      for elem, idx in [ 2, 1, 3, 4 ]
        ul.at_(idx).should.equal(elem)

    it 'should handle duplicate tailmoves', ->
      ol = new List([ 1, 2, 3, 3, 4, 2, 3 ])
      ul = ol.uniq()

      ol.moveAt(3, 4)
      ul.length_.should.equal(4)
      for elem, idx in [ 1, 2, 3, 4 ]
        ul.at_(idx).should.equal(elem)

      ol.moveAt(5, 2)
      ul.length_.should.equal(4)
      for elem, idx in [ 1, 2, 3, 4 ]
        ul.at_(idx).should.equal(elem)

    it 'should handle duplicate headmoves', ->
      ol = new List([ 1, 2, 3, 3, 4, 2, 3 ])
      ul = ol.uniq()

      ol.moveAt(2, 1)
      ul.length_.should.equal(4)
      for elem, idx in [ 1, 3, 2, 4 ]
        ul.at_(idx).should.equal(elem)

      ol.moveAt(1, 0)
      ul.length_.should.equal(4)
      for elem, idx in [ 3, 1, 2, 4 ]
        ul.at_(idx).should.equal(elem)

      ol.moveAt(0, -1)
      ul.length_.should.equal(4)
      for elem, idx in [ 1, 2, 3, 4 ]
        ul.at_(idx).should.equal(elem)

      ol.moveAt(2, -1)
      ul.length_.should.equal(4)
      for elem, idx in [ 1, 2, 4, 3 ]
        ul.at_(idx).should.equal(elem)

