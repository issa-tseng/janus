should = require('should')

{ Model } = require('../../../lib/model/model')
{ List } = require('../../../lib/collection/list')

describe 'collection', ->
  describe 'uniq list', ->
    it 'should return a new list with duplicates omitted', ->
      l = (new List([ 1, 2, 3, 3, 4, 2 ])).uniq()
      l.length.should.equal(4)
      for elem, idx in [ 1, 2, 3, 4 ]
        l.at(idx).should.equal(elem)

    it 'should handle added elements', ->
      ol = new List([ 1, 2, 3, 3, 4, 2 ])
      ul = ol.uniq()

      ol.add(5)
      ul.length.should.equal(5)
      for elem, idx in [ 1, 2, 3, 4, 5 ]
        ul.at(idx).should.equal(elem)

      ol.add(5)
      ul.length.should.equal(5)
      for elem, idx in [ 1, 2, 3, 4, 5 ]
        ul.at(idx).should.equal(elem)

      ol.add(2)
      ul.length.should.equal(5)
      for elem, idx in [ 1, 2, 3, 4, 5 ]
        ul.at(idx).should.equal(elem)

    it 'should handle removed elements', ->
      ol = new List([ 1, 2, 3, 3, 4, 2 ])
      ul = ol.uniq()

      ol.removeAt(2) # 1 2 3 4 2
      ul.length.should.equal(4)
      for elem, idx in [ 1, 2, 3, 4 ]
        ul.at(idx).should.equal(elem)

      ol.removeAt(2) # 1 2 4 2
      ul.length.should.equal(3)
      for elem, idx in [ 1, 2, 4 ]
        ul.at(idx).should.equal(elem)

