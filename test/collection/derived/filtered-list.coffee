should = require('should')

Model = require('../../../lib/model/model').Model

Varying = require('../../../lib/core/varying').Varying
{ List } = require('../../../lib/collection/list')

describe 'collection', ->
  describe 'filtered list', ->
    it 'should by default return a new list identical to the original', ->
      l = (new List([ 1, 2, 3, 4 ])).filter(-> true)
      l.length.should.equal(4)
      for elem, idx in [ 1, 2, 3, 4 ]
        l.at(idx).should.equal(elem)

    it 'should filter out results that return false', ->
      l = (new List([ 1, 2, 3, 4, 5, 6 ])).filter((x) -> (x % 2) is 0)
      l.length.should.equal(3)
      for elem, idx in [ 2, 4, 6 ]
        l.at(idx).should.equal(elem)

    it 'should apply its filter to new entries in the parent list', ->
      ol = new List([ 1, 2, 3, 4, 5, 6 ])
      fl = ol.filter((x) -> (x % 2) is 0)

      ol.add([ 7, 8 ])
      fl.length.should.equal(4)
      for elem, idx in [ 2, 4, 6, 8 ]
        fl.at(idx).should.equal(elem)

      ol.add([ -1, 0 ], 0)
      fl.length.should.equal(5)
      for elem, idx in [ 0, 2, 4, 6, 8 ]
        fl.at(idx).should.equal(elem)

      ol.add(30, 5)
      fl.length.should.equal(6)
      for elem, idx in [ 0, 2, 30, 4, 6, 8 ]
        fl.at(idx).should.equal(elem)

    it 'should remove entries when removed from the parent', ->
      ol = new List([ 1, 2, 3, 4, 5, 6 ])
      fl = ol.filter((x) -> (x % 2) is 0)

      ol.remove(3)
      fl.length.should.equal(3)
      for elem, idx in [ 2, 4, 6 ]
        fl.at(idx).should.equal(elem)

      ol.remove(2)
      fl.length.should.equal(2)
      for elem, idx in [ 4, 6 ]
        fl.at(idx).should.equal(elem)

    it 'should move entries when moved in the parent', ->
      ol = new List([ 1, 2, 3, 4, 5, 6 ])
      fl = ol.filter((x) -> (x % 2) is 0)

      # nonmember -> earlier (start of list).
      ol.moveAt(2, 0) # 3 1 2 4 5 6
      fl.length.should.equal(3)
      for elem, idx in [ 2, 4, 6 ]
        fl.at(idx).should.equal(elem)

      # member -> later.
      ol.moveAt(2, 4) # 3 1 4 5 2 6
      fl.length.should.equal(3)
      for elem, idx in [ 4, 2, 6 ]
        fl.at(idx).should.equal(elem)

      # member (end of list) -> earlier (start of list).
      ol.moveAt(5, 0) # 6 3 1 4 5 2
      fl.length.should.equal(3)
      for elem, idx in [ 6, 4, 2 ]
        fl.at(idx).should.equal(elem)

      # member -> earlier (midlist).
      ol.moveAt(5, 2) # 6 3 2 1 4 5
      fl.length.should.equal(3)
      for elem, idx in [ 6, 2, 4 ]
        fl.at(idx).should.equal(elem)

      # nonmember -> earlier.
      ol.moveAt(3, 2) # 6 3 1 2 4 5
      fl.length.should.equal(3)
      for elem, idx in [ 6, 2, 4 ]
        fl.at(idx).should.equal(elem)

      # move the first item somewhere.
      ol.moveAt(0, 3) # 3 1 2 6 4 5
      fl.length.should.equal(3)
      for elem, idx in [ 2, 6, 4 ]
        fl.at(idx).should.equal(elem)

    it 'should accept a Varying and use its result to determine membership', ->
      v = new Varying((x) -> (x % 2) is 0)
      ol = new List([ 1, 2, 3, 4, 5, 6 ])
      fl = ol.filter((x) -> v.map((f) -> f(x)))

      fl.length.should.equal(3)
      for elem, idx in [ 2, 4, 6 ]
        fl.at(idx).should.equal(elem)

      v.set((x) -> (x % 2) is 0 or x is 5)
      fl.length.should.equal(4)
      for elem, idx in [ 2, 4, 5, 6 ]
        fl.at(idx).should.equal(elem)

      v.set((x) -> x < 4)
      fl.length.should.equal(3)
      for elem, idx in [ 1, 2, 3 ]
        fl.at(idx).should.equal(elem)

    it 'should booleanify values to prevent double-remove', ->
      tl = new List([ null, null ])
      ol = new List([ 0 ])
      fl = ol.filter((x) -> tl.watchAt(x))

      fl.length.should.equal(0)
      ol.add(1)
      fl.length.should.equal(0)
      tl.put(true, 1)
      fl.length.should.equal(1)
      fl.at(0).should.equal(1)
      tl.put(false, 1)
      fl.length.should.equal(0)

