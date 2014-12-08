should = require('should')

{ Varying, Varied, FlatMappedVarying, FlattenedVarying, MappedVarying, ComposedVarying } = require('../../lib/core/varying')

describe.only 'Varying', ->
  describe 'core', ->
    it 'should construct', ->
      (new Varying()).should.be.an.instanceof(Varying)

    it 'should have a value', ->
      (new Varying(4)).get().should.equal(4)

    it 'should allow flat creation', ->
      v = Varying.ly(1)
      v.should.be.an.instanceof(Varying)
      v.get().should.equal(1)

      v = Varying.ly(new Varying(2))
      v.should.be.an.instanceof(Varying)
      v.get().should.equal(2)

  describe 'react', ->
    it 'should react to new values on react()', ->
      results = []
      v = new Varying(1)
      v.react((x) -> results.push(x))

      v.set(2)
      v.set(3)

      results.should.eql([ 2, 3 ])

    it 'should react immediately and on new values on reactNow()', ->
      results = []
      v = new Varying(1)
      v.reactNow((x) -> results.push(x))

      v.set(2)
      v.set(3)

      results.should.eql([ 1, 2, 3 ])

    it 'should return an instance of Varied on react()', ->
      (new Varying()).react().should.be.an.instanceof(Varied)

    it 'should bind this to the Varied within the handler', ->
      v = new Varying(1)
      t = null

      r = v.reactNow(-> t = this)
      r.should.equal(t)

      v.set(2)
      r.should.equal(t)

    it 'should cease reacting on stopped handlers', ->
      runCount = 0
      v = new Varying(1)

      r = v.react(-> runCount += 1)
      v.set(2)
      runCount.should.equal(1)

      r.stop()
      v.set(3)
      runCount.should.equal(1)

    it 'should cease reacting on stopped immediate handlers', ->
      runCount = 0
      v = new Varying(1)

      r = v.reactNow(-> runCount += 1)
      v.set(2)
      runCount.should.equal(2)

      r.stop()
      v.set(3)
      runCount.should.equal(2)

  describe 'map', ->
    it 'should return a MappedVarying when map is called', ->
      (new Varying()).map().should.be.an.instanceof(MappedVarying)

    it 'should be able to directly get a value', ->
      (new Varying(1)).map((x) -> x * 2).get().should.equal(2)

    it 'should callback with a mapped value when react is called', ->
      v = new Varying(1)
      m = v.map((x) -> x * 2)

      result = 0
      m.react((x) -> result = x)

      v.set(2)
      result.should.equal(4)

    it 'should callback immediately with a mapped value when react is called', ->
      v = new Varying(1)
      m = v.map((x) -> x * 2)

      result = 0
      m.reactNow((x) -> result = x)
      result.should.equal(2)

      v.set(2)
      result.should.equal(4)

    it 'should bind this to the Varied within the handler', ->
      v = new Varying(1)
      m = v.map((x) -> x * 2)
      t = null

      r = m.reactNow(-> t = this)
      r.should.equal(t)

      v.set(2)
      r.should.equal(t)

    it 'should cease reacting on stopped handlers', ->
      v = new Varying(1)
      m = v.map((x) -> x * 2)

      runCount = 0
      r = m.react(-> runCount += 1)

      v.set(2)
      runCount.should.equal(1)

      r.stop()
      v.set(3)
      runCount.should.equal(1)

    it 'should stop reacting internally on the parent when something stops reacting to it', ->
      v = new Varying(1)
      m = v.map((x) -> x * 2)

      m.react(->).stop()

      observers = 0
      (observers += 1) for _ of v._observers
      observers.should.equal(0)

    it 'should not flatten results', ->
      v = new Varying(1)
      m = v.map((x) -> new Varying(x))

      result = null
      m.reactNow((x) -> result = x)

      result.should.be.an.instanceof(Varying)
      result.get().should.equal(1)

  describe 'flatten', ->
    it 'should return a FlattenedVarying when map is called', ->
      (new Varying()).flatten().should.be.an.instanceof(FlattenedVarying)

    it 'should be able to directly get a value', ->
      (new Varying(3)).flatten().get().should.equal(3)
      (new Varying(new Varying(4))).flatten().get().should.equal(4)

    it 'should only flatten one level', ->
      v = (new Varying(new Varying(new Varying(5)))).flatten().get()
      v.should.be.an.instanceof(Varying)
      v.get().should.equal(5)

    it 'should callback with a flattened value when react is called', ->
      v = new Varying(1)
      f = v.flatten()

      result = null
      f.react((x) -> result = x)

      v.set(2)
      result.should.equal(2)

      v.set(new Varying(3))
      result.should.equal(3)

    it 'should callback immediately with a flattened value when react is called', ->
      v = new Varying(1)
      f = v.flatten()

      result = null
      f.reactNow((x) -> result = x)
      result.should.equal(1)

      v.set(new Varying(2))
      result.should.equal(2)

    it 'should only flatten one level within react', ->
      v = new Varying(1)
      f = v.flatten()

      result = null
      f.reactNow((x) -> result = x)

      v.set(new Varying(new Varying(2)))
      result.should.be.an.instanceof(Varying)
      result.get().should.equal(2)

    it 'should re-react to an inner varying after flattening', ->
      v = new Varying()
      f = v.flatten()

      result = null
      f.reactNow((x) -> result = x)

      i = new Varying(1)
      v.set(i)
      result.should.equal(1)

      i.set(2)
      result.should.equal(2)

    it 'should cease reacting to an inner varying once it is gone', ->
      v = new Varying()
      f = v.flatten()

      result = null
      f.reactNow((x) -> result = x)

      i = new Varying(1)
      v.set(i)
      result.should.equal(1)

      v.set(0)
      i.set(2)
      result.should.equal(0)

    it 'should internally stop reacting to an inner varying once it is gone', ->
      v = new Varying()
      f = v.flatten()

      f.reactNow((x) -> result = x)

      i = new Varying(1)
      v.set(i)
      v.set(0)

      observers = 0
      (observers += 1) for _ of i._observers
      observers.should.equal(0)

# describe 'flatMap', ->

# describe 'side effects', ->
#   it 'should not re-execute orphaned propagations', ->

# describe 'pure', ->

