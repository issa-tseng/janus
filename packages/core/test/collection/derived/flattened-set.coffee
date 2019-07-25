should = require('should')
{ Set } = require('../../../lib/collection/set')

describe 'collection', ->
  describe 'FlattenedSet', ->
    it 'should start with parent basic elements', ->
      flattened = (new Set([ 1, 2, 3, 3, 4, 2 ])).flatten()
      flattened.length_.should.equal(4)
      for x in [ 1, 2, 3, 4 ]
        flattened.includes_(x).should.equal(true)

    it 'should start with parent nested elements', ->
      flattened = (new Set([ 1, 2, new Set([ 1, 3 ]), new Set([ 3, 4 ]) ])).flatten()
      flattened.length_.should.equal(4)
      for x in [ 1, 2, 3, 4 ]
        flattened.includes_(x).should.equal(true)

    it 'should track parent primitive changes', ->
      og = new Set([ 1, 2 ])
      flattened = og.flatten()

      og.add(4)
      flattened.length_.should.equal(3)
      flattened.includes_(4).should.equal(true)

      og.add(4)
      flattened.length_.should.equal(3)

      og.remove(2)
      flattened.length_.should.equal(2)
      flattened.includes_(2).should.equal(false)

    it 'should track flattened subelements on change', ->
      og = new Set([ 1, 2 ])
      flattened = og.flatten()

      nest1 = new Set([ 2, 3, 4 ])
      og.add(nest1)
      flattened.length_.should.equal(4)
      flattened.includes_(3).should.equal(true)
      flattened.includes_(4).should.equal(true)

      nest2 = new Set([ 1, 3, 5 ])
      og.add(nest2)
      flattened.length_.should.equal(5)
      flattened.includes_(5).should.equal(true)

      og.remove(nest1)
      flattened.length_.should.equal(4)
      flattened.includes_(4).should.equal(false)

      og.remove(nest2)
      flattened.length_.should.equal(2)
      flattened.includes_(5).should.equal(false)

      og.remove(1)
      flattened.length_.should.equal(1)
      flattened.includes_(1).should.equal(false)

    it 'should track child subelement changes', ->
      og = new Set([ 1, 2 ])
      flattened = og.flatten()

      nest1 = new Set([ 2, 3 ])
      og.add(nest1)
      nest1.add(4)
      flattened.length_.should.equal(4)
      flattened.includes_(4).should.equal(true)

      nest1.remove(2)
      flattened.length_.should.equal(4)

      nest2 = new Set([ 4 ])
      og.add(nest2)
      nest2.add(3)
      flattened.length_.should.equal(4)

      nest2.remove(4)
      flattened.length_.should.equal(4)

    it 'should not flatten more than one level', ->
      inner = new Set([ 5 ])
      mid = new Set([ 3, 4, inner ])
      outer = new Set([ 1, 2, mid ])
      flattened = outer.flatten()

      flattened.length_.should.equal(5)
      flattened.includes_(inner).should.equal(true)

      inner.add(6)
      flattened.length_.should.equal(5)

    it 'should stop listening to child changes when they leave', ->
      inner = new Set()
      outer = new Set([ 1, 2, inner ])
      flattened = outer.flatten()
      outer.remove(inner)
      inner.add(3)
      flattened.length_.should.equal(2)

    it 'should never attempt to flatten its parent (on create)', ->
      basiliskparrot = new Set([ 1, 2 ])
      basiliskparrot.add(basiliskparrot)
      flattened = basiliskparrot.flatten()
      flattened.length_.should.equal(3)
      flattened.includes_(basiliskparrot).should.equal(true)

    it 'should never attempt to flatten its parent (on dynamic add)', ->
      parrot = new Set([ 1, 2 ])
      flattened = parrot.flatten()
      parrot.add(parrot)
      flattened.length_.should.equal(3)
      flattened.includes_(parrot).should.equal(true)

    it 'should not accidentally unlisten to the parent', ->
      parrot = new Set([ 1, 2 ])
      flattened = parrot.flatten()
      parrot.add(parrot)
      parrot.remove(parrot)
      parrot.add(3)
      flattened.length_.should.equal(3)
      flattened.includes_(3).should.equal(true)

    it 'should never try to flatten itself', ->
      bwahhh = new Set([ 1, 2 ])
      flattened = bwahhh.flatten()
      bwahhh.add(flattened)

      flattened.length_.should.equal(3)
      flattened.includes_(flattened).should.equal(true)

