should = require('should')

{ Varying, Varied, FlatMappedVarying, FlattenedVarying, MappedVarying, ComposedVarying } = require('../../lib/core/varying')

countObservers = (o) ->
  observers = 0
  (observers += 1) for _ of o._observers
  observers

describe 'Varying', ->
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

    it 'should not re-react to old values on react()', ->
      results = []
      v = new Varying(1)
      v.react((x) -> results.push(x))

      v.set(2)
      v.set(2)

      results.should.eql([ 2 ])

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

    it 'should not flatten on get', ->
      (new Varying(1)).map((x) -> new Varying(x * 2)).get().should.be.an.instanceof(Varying)

    it 'should callback with a mapped value when react is called', ->
      v = new Varying(1)
      m = v.map((x) -> x * 2)

      result = 0
      m.react((x) -> result = x)

      v.set(2)
      result.should.equal(4)

    it 'should not callback with a dupe mapped value when react is called', ->
      v = new Varying(1)
      m = v.map(-> 4)

      count = 0
      m.reactNow((x) -> count += 1)

      v.set(2)
      v.set(3)
      count.should.equal(1)

    it 'should callback immediately with a mapped value when react is called', ->
      v = new Varying(1)
      m = v.map((x) -> x * 2)

      result = 0
      m.reactNow((x) -> result = x)
      result.should.equal(2)

      v.set(2)
      result.should.equal(4)

    it 'should not flatten on react', ->
      v = new Varying(1)
      m = v.map((x) -> new Varying(x * 2))

      result = null
      m.reactNow((x) -> result = x)

      result.should.be.an.instanceof(Varying)
      result.get().should.equal(2)

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

      countObservers(v).should.equal(0)

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

    it 'should re-react to an inner varying set before flattening', ->
      i = new Varying(1)
      v = new Varying(i)
      f = v.flatten()

      result = null
      f.reactNow((x) -> result = x)
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

    it 'should cease reacting to an inner varying when it does', ->
      v = new Varying()
      f = v.flatten()

      i = new Varying(1)

      result = null
      r = f.reactNow((x) -> result = x)

      v.set(i)
      result.should.equal(1)

      r.stop()
      i.set(2)
      result.should.equal(1)

    it 'should internally stop reacting to an inner varying once it is gone', ->
      v = new Varying()
      f = v.flatten()

      f.reactNow((x) -> result = x)

      i = new Varying(1)
      v.set(i)
      v.set(0)

      countObservers(i).should.equal(0)

  describe 'flatMap', ->
    it 'should return a FlatMappedVarying when map is called', ->
      (new Varying()).flatMap().should.be.an.instanceof(FlatMappedVarying)

    it 'should be able to directly get a value', ->
      (new Varying(1)).flatMap((x) -> x * 2).get().should.equal(2)
      (new Varying(3)).flatMap((x) -> new Varying(x * 2)).get().should.equal(6)

    it 'should only flatten one level', ->
      v = (new Varying(4)).flatMap((x) -> new Varying(new Varying(x * 2))).get()
      v.should.be.an.instanceof(Varying)
      v.get().should.equal(8)

    it 'should callback with a flatmapped value when react is called', ->
      v = new Varying(1)
      m = v.flatMap((x) -> new Varying(x * 2))

      result = 0
      m.react((x) -> result = x)

      v.set(2)
      result.should.equal(4)

    it 'should callback immediately with a flatmapped value when react is called', ->
      v = new Varying(1)
      m = v.flatMap((x) -> new Varying(x * 2))

      result = 0
      m.reactNow((x) -> result = x)
      result.should.equal(2)

      v.set(2)
      result.should.equal(4)

    it 'should bind this to the Varied within the handler', ->
      v = new Varying(1)
      m = v.flatMap((x) -> x * 2)
      t = null

      r = m.reactNow(-> t = this)
      r.should.equal(t)

      v.set(2)
      r.should.equal(t)

    it 'should cease reacting on stopped handlers', ->
      v = new Varying(1)
      m = v.flatMap((x) -> x * 2)

      runCount = 0
      r = m.react(-> runCount += 1)

      v.set(2)
      runCount.should.equal(1)

      r.stop()
      v.set(3)
      runCount.should.equal(1)

    it 'should re-react to an inner varying after flatMapping', ->
      v = new Varying()
      i = null
      m = v.flatMap((x) -> i = new Varying(x * 2))

      result = null
      m.reactNow((x) -> result = x)

      v.set(1)
      result.should.equal(2)

      i.set(3)
      result.should.equal(3)

    it 'should cease reacting to an inner varying once it is gone', ->
      v = new Varying()
      i = null
      m = v.flatMap((x) -> i = new Varying(x * 2))

      result = null
      m.reactNow((x) -> result = x)

      v.set(1)
      i2 = i

      v.set(2)
      i2.set(3)
      result.should.equal(4)


  describe 'side effect management', ->
    it 'should not re-execute orphaned propagations', ->
      v = new Varying()

      # first, set up a reaction that causes a cyclic set.
      hasRetriggered = false
      v.react(-> v.set(2) unless hasRetriggered)

      # next, set up a reaction later in the chain. count its executions.
      runCount = 0
      v.react(-> runCount += 1)

      # now go.
      v.set(1)
      runCount.should.equal(1)

    it 'should provide the right value in a cyclic set', ->
      v = new Varying()

      hasRetriggered = false
      v.react(-> v.set(2) unless hasRetriggered)

      result = null
      v.react((x) -> result = x)

      v.set(1)
      result.should.equal(2)

  describe 'pure', ->
    describe 'application', ->
      it 'should return a ComposedVarying given a, b, c, f', ->
        Varying.pure(new Varying(), new Varying(), new Varying(), ->).should.be.an.instanceof(ComposedVarying)

      it 'should return a ComposedVarying given f, a, b, c', ->
        Varying.pure(((a, b, c) ->), new Varying(), new Varying(), new Varying()).should.be.an.instanceof(ComposedVarying)

      it 'should return a curryable function given (a -> b -> c -> x), a, b', ->
        f = Varying.pure(((a, b, c) ->), new Varying(), new Varying())
        f.should.be.a.Function

        f(new Varying()).should.be.an.instanceof(ComposedVarying)

      it 'should expose mapAll as a synonym for pure', ->
        Varying.mapAll(new Varying(), new Varying(), new Varying(), ->).should.be.an.instanceof(ComposedVarying)

    describe 'mapAll', ->
      it 'should be able to directly get a value', ->
        Varying.pure(((x, y) -> x + y), new Varying(1), new Varying(2)).get().should.equal(3)

      it 'should not flatten on get', ->
        Varying.pure(((x, y) -> new Varying(x + y)), new Varying(1), new Varying(2)).get().should.be.an.instanceof(Varying)

      it 'should callback with a mapped value when react is called', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.pure(((x, y) -> x + y), va, vb)

        result = 0
        m.react((x) -> result = x)

        va.set(3)
        result.should.equal(5)

        vb.set(4)
        result.should.equal(7)

      it 'should callback immediately with a mapped value when reactNow is called', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.pure(((x, y) -> x + y), va, vb)

        result = 0
        m.reactNow((x) -> result = x)
        result.should.equal(3)

        vb.set(4)
        result.should.equal(5)

      it 'should not flatten on react', ->
        m = Varying.pure(((x, y) -> new Varying(x + y)), new Varying(1), new Varying(2))

        result = null
        m.reactNow((x) -> result = x)

        result.should.be.an.instanceof(Varying)
        result.get().should.equal(3)

      it 'should bind this to the Varied within the handler', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.pure(((x, y) -> new Varying(x + y)), va, vb)
        t = null

        r = m.reactNow(-> t = this)
        r.should.equal(t)

        va.set(2)
        r.should.equal(t)

      it 'should cease reacting on stopped handlers', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.pure(((x, y) -> new Varying(x + y)), va, vb)

        runCount = 0
        r = m.react((x) -> runCount += 1)
        runCount.should.equal(0)

        va.set(2)
        runCount.should.equal(1)

        r.stop()
        va.set(3)
        runCount.should.equal(1)

      it 'should stop reacting internally on the parent when something stops reacting to it', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.pure(((x, y) -> x + y), va, vb)

        m.reactNow(->).stop()

        countObservers(va).should.equal(0)
        countObservers(vb).should.equal(0)

    describe 'flatMapAll', ->
      it 'should flatten on get', ->
        Varying.flatMapAll(((x, y) -> new Varying(x + y)), new Varying(1), new Varying(2)).get().should.be.equal(3)

      it 'should callback with a flatmapped value when react is called', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.flatMapAll(((x, y) -> new Varying(x + y)), va, vb)

        result = 0
        m.react((x) -> result = x)

        va.set(3)
        result.should.equal(5)

        vb.set(4)
        result.should.equal(7)

      it 'should callback immediately with a flatmapped value when reactNow is called', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.flatMapAll(((x, y) -> new Varying(x + y)), va, vb)

        result = 0
        m.reactNow((x) -> result = x)
        result.should.equal(3)

        vb.set(4)
        result.should.equal(5)

      it 'should flatten on react', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.flatMapAll(((x, y) -> new Varying(x + y)), va, vb)

        result = null
        m.reactNow((x) -> result = x)

        result.should.equal(3)

      it 'should re-react to an inner varying after flatMapping', ->
        va = new Varying(1)
        vb = new Varying(2)
        vz = null
        m = Varying.flatMapAll(((x, y) -> vz = new Varying(x + y)), va, vb)

        result = null
        m.reactNow((x) -> result = x)

        va.set(3)
        result.should.equal(5)

        vz.set(6)
        result.should.equal(6)

      it 'should re-react to an inner varying set before flatMapping', ->
        vz = null
        m = Varying.flatMapAll(((x, y) -> vz = new Varying(x + y)), new Varying(1), new Varying(2))

        result = null
        m.reactNow((x) -> result = x)
        result.should.equal(3)

        vz.set(4)
        result.should.equal(4)

      it 'should cease reacting to an inner varying once it is gone', ->
        va = new Varying(1)
        vb = new Varying(2)
        vx = null
        m = Varying.flatMapAll(((x, y) -> vx = new Varying(x + y)), va, vb)

        result = null
        m.reactNow((x) -> result = x)

        va.set(1)
        vz = vx

        va.set(3)
        vz.set(4)
        result.should.equal(5)

