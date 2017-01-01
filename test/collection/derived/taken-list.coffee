should = require('should')

{ Varying } = require('../../../lib/core/varying')
{ Model } = require('../../../lib/model/model')
{ List } = require('../../../lib/collection/list')

describe 'collection', ->
  describe 'taken list', ->
    it 'should return a new list with the correct number of elements', ->
      l = (new List([ 1, 2, 3, 4 ])).take(2)
      l.length.should.equal(2)
      for elem, idx in [ 1, 2 ]
        l.at(idx).should.equal(elem)

      l = (new List([ 1, 2, 3, 4 ])).take(10)
      l.length.should.equal(4)
      for elem, idx in [ 1, 2, 3, 4 ]
        l.at(idx).should.equal(elem)

    it 'should handle a changing take value via a Varying', ->
      v = new Varying(3)
      l = (new List([ 1, 2, 3, 4, 5, 6, 7, 8 ])).take(v)

      l.length.should.equal(3)
      for elem, idx in [ 1, 2, 3 ]
        l.at(idx).should.equal(elem)

      v.set(6)
      l.length.should.equal(6)
      for elem, idx in [ 1, 2, 3, 4, 5, 6 ]
        l.at(idx).should.equal(elem)

      v.set(2)
      l.length.should.equal(2)
      for elem, idx in [ 1, 2 ]
        l.at(idx).should.equal(elem)

    it 'should handle additions to the original list', ->
      ol = new List([ 1, 2, 3, 4 ])
      tl = ol.take(5)

      ol.add(5)
      tl.length.should.equal(5)
      for elem, idx in [ 1, 2, 3, 4, 5 ]
        tl.at(idx).should.equal(elem)

      ol.add(6)
      tl.length.should.equal(5)
      for elem, idx in [ 1, 2, 3, 4, 5 ]
        tl.at(idx).should.equal(elem)

      ol.add(0, 0)
      tl.length.should.equal(5)
      for elem, idx in [ 0, 1, 2, 3, 4 ]
        tl.at(idx).should.equal(elem)

    it 'should handle removals from the old list', ->
      ol = new List([ 1, 2, 3, 4, 5, 6, 7 ])
      tl = ol.take(5)

      ol.removeAt(6)
      tl.length.should.equal(5)
      for elem, idx in [ 1, 2, 3, 4, 5 ]
        tl.at(idx).should.equal(elem)

      ol.removeAt(2)
      tl.length.should.equal(5)
      for elem, idx in [ 1, 2, 4, 5, 6 ]
        tl.at(idx).should.equal(elem)

      ol.removeAt(0)
      tl.length.should.equal(4)
      for elem, idx in [ 2, 4, 5, 6 ]
        tl.at(idx).should.equal(elem)

    it 'should handle moves within the parent list', ->
      ol = new List([ 1, 2, 3, 4, 5, 6, 7 ])
      tl = ol.take(5)

      # move within range.
      ol.moveAt(1, 3) # 1 3 4 2 5 | 6 7
      tl.length.should.equal(5)
      for elem, idx in [ 1, 3, 4, 2, 5 ]
        tl.at(idx).should.equal(elem)

      # move to out of range.
      ol.moveAt(3, 5) # 1 3 4 5 6 | 2 7
      tl.length.should.equal(5)
      for elem, idx in [ 1, 3, 4, 5, 6 ]
        tl.at(idx).should.equal(elem)

      # move from out of range.
      ol.moveAt(6, 0) # 7 1 3 4 5 | 6 2
      tl.length.should.equal(5)
      for elem, idx in [ 7, 1, 3, 4, 5 ]
        tl.at(idx).should.equal(elem)

      # noop move.
      ol.moveAt(6, 5) # 7 1 3 4 5 | 2 6
      tl.length.should.equal(5)
      for elem, idx in [ 7, 1, 3, 4, 5 ]
        tl.at(idx).should.equal(elem)

