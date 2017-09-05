should = require('should')

{ Model } = require('../../lib/model/model')
{ Set } = require('../../lib/collection/set')

describe 'collection', ->
  describe 'set', ->
    it 'should return a set with duplicates omitted', ->
      s = new Set([ 1, 2, 3, 3, 4, 2 ])
      s.length.should.equal(4)
      for elem in [ 1, 2, 3, 4 ]
        s.has(elem).should.equal(true)

    it 'should take in new unique elements', ->
      s = new Set([ 1, 2, 3, 3, 4, 2 ])

      s.add(2)
      s.add(1)
      s.add(6)

      s.length.should.equal(5)
      for elem in [ 1, 2, 3, 4, 6 ]
        s.has(elem).should.equal(true)

    it 'should remove elements', ->
      s = new Set([ 1, 2, 3, 3, 4, 2 ])

      s.remove(2)
      s.length.should.equal(3)
      for elem in [ 1, 3, 4 ]
        s.has(elem).should.equal(true)

      s.remove(6)
      s.length.should.equal(3)
      for elem in [ 1, 3, 4 ]
        s.has(elem).should.equal(true)

    it 'should allow watching whether the set has an element', ->
      results = []
      s = new Set([ 1, 2, 3, 3, 4, 2 ])

      v1 = s.watchHas(2)
      v2 = s.watchHas(6)
      v1.react((x) -> results.push(1, x))
      v2.react((x) -> results.push(2, x))

      s.remove(2)
      s.add(6)
      s.add(2)

      results.should.eql([ 1, true, 2, false, 1, false, 2, true, 1, true ])

    it 'should allow full replacement via putAll', ->
      s = new Set([ 1, 2, 3, 3, 4, 2 ])
      s.putAll([ 4, 8, 15, 16, 23, 42, 4, 15 ])

      s.length.should.equal(6)
      for elem in [ 4, 8, 15, 16, 23, 42 ]
        s.has(elem).should.equal(true)
      for elem in [ 1, 2, 3 ]
        s.has(elem).should.equal(false)

    it 'should not have index-related methods', ->
      s = new Set()
      for method in [ 'at', 'watchAt', 'removeAt', 'move', 'moveAt', 'put' ]
        should(s[method]).equal(undefined)

