should = require('should')

Model = require('../../../lib/model/model').Model
{ List } = require('../../../lib/collection/list')

describe 'collection', ->
  describe 'flattened list', ->
    it 'should return a new list equivalent to the original given primitives', ->
      l = (new List([ 1, 2, 3, 4 ])).flatten()
      l.length.should.equal(4)
      for elem, idx in [ 1, 2, 3, 4 ]
        l.at(idx).should.equal(elem)

    it 'should return a flattened list when given a nested list', ->
      l = (new List([ 1, 2, new List([ 3, 4 ]), 5, new List([ 6 ]) ])).flatten()
      l.length.should.equal(6)
      for elem, idx in [ 1, 2, 3, 4, 5, 6 ]
        l.at(idx).should.equal(elem)

    it 'should handle additions to the original list', ->
      ol = new List([ 1, 2, new List([ 3, 4 ]), 5, new List([ 6 ]) ])
      fl = ol.flatten()

      ol.at(2).add(4.5) # [ 1 2 [ 3 4 4.5 ] 5 [ 6 ] ]
      fl.length.should.equal(7)
      for elem, idx in [ 1, 2, 3, 4, 4.5, 5, 6 ]
        fl.at(idx).should.equal(elem)

      ol.add(5.5, 4) # [ 1 2 [ 3 4 4.5 ] 5 5.5 [ 6 ] ]
      fl.length.should.equal(8)
      for elem, idx in [ 1, 2, 3, 4, 4.5, 5, 5.5, 6 ]
        fl.at(idx).should.equal(elem)

    it 'should handle removals from the original list', ->
      ol = new List([ 1, 2, new List([ 3, 4 ]), 5, new List([ 6 ]) ])
      fl = ol.flatten()

      ol.at(2).removeAt(0) # [ 1 2 [ 4 ] 5 [ 6 ] ]
      fl.length.should.equal(5)
      for elem, idx in [ 1, 2, 4, 5, 6 ]
        fl.at(idx).should.equal(elem)

      ol.at(2).removeAt(0) # [ 1 2 [] 5 [ 6 ] ]
      fl.length.should.equal(4)
      for elem, idx in [ 1, 2, 5, 6 ]
        fl.at(idx).should.equal(elem)

      ol.removeAt(3) # [ 1 2 [] [ 6 ] ]
      fl.length.should.equal(3)
      for elem, idx in [ 1, 2, 6 ]
        fl.at(idx).should.equal(elem)

    it 'should handle new lists in the original list', ->
      ol = new List([ 1, 2, new List([ 3, 4 ]), 5, new List([ 6 ]) ])
      fl = ol.flatten()

      ol.add(new List([ 'a', 'b' ]), 3) # [ 1 2 [ 3 4 ] [ a b ] 5 [ 6 ] ]
      fl.length.should.equal(8)
      for elem, idx in [ 1, 2, 3, 4, 'a', 'b', 5, 6 ]
        fl.at(idx).should.equal(elem)

      ol.at(3).add('z', 1) # [ 1 2 [ 3 4 ] [ a z b ] 5 [ 6 ] ]
      fl.length.should.equal(9)
      for elem, idx in [ 1, 2, 3, 4, 'a', 'z', 'b', 5, 6 ]
        fl.at(idx).should.equal(elem)

    it 'should handle removed lists from the original list', ->
      ol = new List([ 1, 2, new List([ 3, 4 ]), 5, new List([ 6 ]) ])
      fl = ol.flatten()

      rl = ol.removeAt(2) # [ 1 2 5 [ 6 ] ]
      fl.length.should.equal(4)
      for elem, idx in [ 1, 2, 5, 6 ]
        fl.at(idx).should.equal(elem)

      rl.removeAt(0) # noop
      fl.length.should.equal(4)
      for elem, idx in [ 1, 2, 5, 6 ]
        fl.at(idx).should.equal(elem)

    it 'should handle moved toplevel objects', ->
      ol = new List([ 1, 2, new List([ 3, 4 ]), 5, new List([ 6 ]) ])
      fl = ol.flatten()

      # primitive element back.
      ol.moveAt(0, 2) # [ 2 [ 3 4 ] 1 5 [ 6 ] ]
      fl.length.should.equal(6)
      for elem, idx in [ 2, 3, 4, 1, 5, 6 ]
        fl.at(idx).should.equal(elem)

      # list back.
      ol.moveAt(1, 3) # [ 2 1 5 [ 3 4 ] [ 6 ] ]
      fl.length.should.equal(6)
      for elem, idx in [ 2, 1, 5, 3, 4, 6 ]
        fl.at(idx).should.equal(elem)

      # shuffling.
      ol.moveAt(4, 1) # [ 2 [ 6 ] 1 5 [ 3 4 ] ]
      fl.length.should.equal(6)
      for elem, idx in [ 2, 6, 1, 5, 3, 4 ]
        fl.at(idx).should.equal(elem)

      # list forward.
      ol.moveAt(4, 1) # [ 2 [ 3 4 ] [ 6 ] 1 5 ]
      fl.length.should.equal(6)
      for elem, idx in [ 2, 3, 4, 6, 1, 5 ]
        fl.at(idx).should.equal(elem)

      # primitive forward.
      ol.moveAt(3, 2) # [ 2 [ 3 4 ] 1 [ 6 ] 5 ]
      fl.length.should.equal(6)
      for elem, idx in [ 2, 3, 4, 1, 6, 5 ]
        fl.at(idx).should.equal(elem)

    it 'should remap list listeners correctly post-move', ->
      ol = new List([ 1, 2, new List([ 3, 4 ]), 5, new List([ 6 ]) ])
      fl = ol.flatten()

      ol.moveAt(2, 3)
      ol.at(3).removeAt(1)

      fl.length.should.equal(5)
      for elem, idx in [ 1, 2, 5, 3, 6 ]
        fl.at(idx).should.equal(elem)

    it 'should handle moved items within a nested list', ->
      ol = new List([ 1, new List([ 2, 3, 4 ]), 5, new List([ 6 ]) ])
      fl = ol.flatten()

      ol.at(1).moveAt(2, 0)
      fl.length.should.equal(6)
      for elem, idx in [ 1, 4, 2, 3, 5, 6 ]
        fl.at(idx).should.equal(elem)

    it 'should no longer pay attention to removed lists', ->
      ol = new List([ 1, new List([ 2, 3, 4 ]), 5, new List([ 6 ]) ])
      fl = ol.flatten()

      sl = ol.removeAt(1)
      sl.removeAt(1)

      fl.length.should.equal(3)
      for elem, idx in [ 1, 5, 6 ]
        fl.at(idx).should.equal(elem)

    it 'should stop listening to the parent on destroy', ->
      ol = new List([ 1, new List([ 2, 3, 4 ]), 5, new List([ 6 ]) ])
      fl = ol.flatten()
      sl = ol.at(1)

      fl.destroy()
      sl.listeners('added').should.eql([])
      sl.listeners('moved').should.eql([])
      sl.listeners('removed').should.eql([])

