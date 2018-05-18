should = require('should')

{ Varying, Observation, FlatMappedVarying, FlattenedVarying, MappedVarying, ComposedVarying } = require('../../lib/core/varying')

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
    it 'should react to new values on reactLater()', ->
      results = []
      v = new Varying(1)
      v.reactLater((x) -> results.push(x))

      v.set(2)
      v.set(3)

      results.should.eql([ 2, 3 ])

    it 'should not re-react to old values on reactLater()', ->
      results = []
      v = new Varying(1)
      v.reactLater((x) -> results.push(x))

      v.set(2)
      v.set(2)

      results.should.eql([ 2 ])

    it 'should react immediately and on new values on react()', ->
      results = []
      v = new Varying(1)
      v.react((x) -> results.push(x))

      v.set(2)
      v.set(3)

      results.should.eql([ 1, 2, 3 ])

    it 'should return an instance of Observation on reactLater()', ->
      (new Varying()).reactLater().should.be.an.instanceof(Observation)

    it 'should bind this to the Observation within the handler', ->
      v = new Varying(1)
      t = null

      r = v.react(-> t = this)
      r.should.equal(t)

      v.set(2)
      r.should.equal(t)

    it 'should cease reacting on stopped handlers', ->
      runCount = 0
      v = new Varying(1)

      r = v.reactLater(-> runCount += 1)
      v.set(2)
      runCount.should.equal(1)

      r.stop()
      v.set(3)
      runCount.should.equal(1)

    it 'should cease reacting on stopped immediate handlers', ->
      runCount = 0
      v = new Varying(1)

      r = v.react(-> runCount += 1)
      v.set(2)
      runCount.should.equal(2)

      r.stop()
      v.set(3)
      runCount.should.equal(2)

  describe 'refCount', ->
    it 'should return a Varying with the number of reactions', ->
      v = new Varying(true)
      v.react(->)
      v.reactLater(->)

      result = v.refCount()
      result.get().should.equal(2)

    it 'should update as the refcount changes', ->
      v = new Varying(true)

      results = []
      v.refCount().react((x) -> results.push(x))

      v.react(-> this.stop())
      v.reactLater()
      results.should.eql([ 0, 1, 0, 1 ])

    it 'should account for chained references', ->
      v = new Varying(true)
      v.map((x) -> !x).react(->)
      v.refCount().get().should.equal(1)

    it 'should work on (flat)mapped varyings', ->
      v = new Varying(true)
      vv = v.flatMap((x) -> !x)

      results = []
      vv.refCount().react((x) -> results.push(x))

      vv.reactLater(->)
      vv.react(-> this.stop())
      results.should.eql([ 0, 1, 2, 1 ])

    it 'should work on composed varyings', ->
      v = Varying.mapAll((->), new Varying(1), new Varying(2), new Varying(3))

      results = []
      v.refCount().react((x) -> results.push(x))

      v.reactLater(->)
      v.react(-> this.stop())
      results.should.eql([ 0, 1, 2, 1 ])

  describe 'bind', ->
    it 'should adopt the initial other value', ->
      vx = new Varying(3)
      vy = new Varying()

      vy.bind(vx)
      vy.get().should.equal(3)

    it 'should update with the other value', ->
      vx = new Varying(3)
      vy = new Varying()
      vy.bind(vx)

      result = null
      vy.react((x) -> result = x)
      vx.set(6)
      result.should.equal(6)

    it 'should disable the ability to set', ->
      v = new Varying()
      v.bind(new Varying())
      should(v.set).equal(undefined)

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
      m.reactLater((x) -> result = x)

      v.set(2)
      result.should.equal(4)

    it 'should not callback with a dupe mapped value when react is called', ->
      v = new Varying(1)
      m = v.map(-> 4)

      count = 0
      m.react((x) -> count += 1)

      v.set(2)
      v.set(3)
      count.should.equal(1)

    it 'should callback immediately with a mapped value when react is called', ->
      v = new Varying(1)
      m = v.map((x) -> x * 2)

      result = 0
      m.react((x) -> result = x)
      result.should.equal(2)

      v.set(2)
      result.should.equal(4)

    it 'should not flatten on react', ->
      v = new Varying(1)
      m = v.map((x) -> new Varying(x * 2))

      result = null
      m.react((x) -> result = x)

      result.should.be.an.instanceof(Varying)
      result.get().should.equal(2)

    it 'should bind this to the Observation within the handler', ->
      v = new Varying(1)
      m = v.map((x) -> x * 2)
      t = null

      r = m.react(-> t = this)
      r.should.equal(t)

      v.set(2)
      r.should.equal(t)

    it 'should cease reacting on stopped handlers', ->
      v = new Varying(1)
      m = v.map((x) -> x * 2)

      runCount = 0
      r = m.reactLater(-> runCount += 1)

      v.set(2)
      runCount.should.equal(1)

      r.stop()
      v.set(3)
      runCount.should.equal(1)

    it 'should stop reacting internally on the parent when something stops reacting to it', ->
      v = new Varying(1)
      m = v.map((x) -> x * 2)

      m.reactLater(->).stop()

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
      f.reactLater((x) -> result = x)

      v.set(2)
      result.should.equal(2)

      v.set(new Varying(3))
      result.should.equal(3)

    it 'should callback immediately with a flattened value when react is called', ->
      v = new Varying(1)
      f = v.flatten()

      result = null
      f.react((x) -> result = x)
      result.should.equal(1)

      v.set(new Varying(2))
      result.should.equal(2)

    it 'should only flatten one level within react', ->
      v = new Varying(1)
      f = v.flatten()

      result = null
      f.react((x) -> result = x)

      v.set(new Varying(new Varying(2)))
      result.should.be.an.instanceof(Varying)
      result.get().should.equal(2)

    it 'should re-react to an inner varying after flattening', ->
      v = new Varying()
      f = v.flatten()

      result = null
      f.react((x) -> result = x)

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
      f.react((x) -> result = x)
      result.should.equal(1)

      i.set(2)
      result.should.equal(2)

    it 'should cease reacting to an inner varying even if it is set to the same value', -> # gh 53
      va = new Varying(true)
      vb = new Varying(42)
      vx = va.flatMap((a) -> if a then vb else 42)

      results = []
      vx.react((x) -> results.push(x))
      va.set(false)
      vb.set(47)
      results.should.eql([ 42 ])

    it 'should cease reacting to an inner varying once it is gone', ->
      v = new Varying()
      f = v.flatten()

      result = null
      f.react((x) -> result = x)

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
      r = f.react((x) -> result = x)

      v.set(i)
      result.should.equal(1)

      r.stop()
      i.set(2)
      result.should.equal(1)

    it 'should internally stop reacting to an inner varying once it is gone', ->
      v = new Varying()
      f = v.flatten()

      f.react((x) -> result = x)

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
      m.reactLater((x) -> result = x)

      v.set(2)
      result.should.equal(4)

    it 'should callback immediately with a flatmapped value when react is called', ->
      v = new Varying(1)
      m = v.flatMap((x) -> new Varying(x * 2))

      result = 0
      m.react((x) -> result = x)
      result.should.equal(2)

      v.set(2)
      result.should.equal(4)

    it 'should bind this to the Observation within the handler', ->
      v = new Varying(1)
      m = v.flatMap((x) -> x * 2)
      t = null

      r = m.react(-> t = this)
      r.should.equal(t)

      v.set(2)
      r.should.equal(t)

    it 'should cease reacting on stopped handlers', ->
      v = new Varying(1)
      m = v.flatMap((x) -> x * 2)

      runCount = 0
      r = m.reactLater(-> runCount += 1)

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
      m.react((x) -> result = x)

      v.set(1)
      result.should.equal(2)

      i.set(3)
      result.should.equal(3)

    it 'should cease reacting to an inner varying once it is gone', ->
      v = new Varying()
      i = null
      m = v.flatMap((x) -> i = new Varying(x * 2))

      result = null
      m.react((x) -> result = x)

      v.set(1)
      i2 = i

      v.set(2)
      i2.set(3)
      result.should.equal(4)

    it 'should attach itself to an inner varying if reacted secondarily', ->
      v = new Varying()
      vv = new Varying(v)

      result = null
      vv.flatMap((x) -> x).map((x) -> x).react((x) -> result = x)

      v.set(2)
      result.should.equal(2)
      v.set(3)
      result.should.equal(3)

    it 'should trip react on inner varying changing before the outer', -> # GH #33
      v = new Varying(2)
      v2 = new Varying(2)

      result = null
      v.flatMap((x) -> v2.map((y) -> x * y)).reactLater((z) -> result = z)
      should(result).equal(null)

      v2.set(3)
      result.should.equal(6)

    it 'behaves as expected when reacted multiple times off a flatMap', ->
      v = new Varying(1)
      vv = new Varying(v)

      flat = vv.flatMap((x) -> x)

      ra = rb = null
      a = flat.react((x) -> ra = x)
      b = flat.react((x) -> rb = x)
      ra.should.equal(1)
      rb.should.equal(1)

      v.set(2)
      ra.should.equal(2)
      rb.should.equal(2)

    it 'still works if just one reaction is stopped', ->
      v = new Varying(1)
      vv = new Varying(v)

      flat = vv.flatMap((x) -> x)

      ra = rb = null
      a = flat.react((x) -> ra = x)
      b = flat.react((x) -> rb = x)
      ra.should.equal(1)
      rb.should.equal(1)

      a.stop()
      v.set(2)
      ra.should.equal(1)
      rb.should.equal(2)

    it 'should dedupe intermediate results for react', -> # gh40
      v = new Varying(1)
      vv = new Varying(0)

      results = []
      vv.flatMap((x) -> v.map((y) -> y)).map((z) -> z + 1).react((w) -> results.push(w))

      vv.set(2)
      vv.set(3)
      v.set(2)
      results.should.eql([ 2, 3 ])

    it 'should dedupe intermediate results for reactLater', -> # gh40
      v = new Varying(1)
      vv = new Varying(0)

      results = []
      vv.flatMap((x) -> v.map((y) -> y)).map((z) -> z + 1).reactLater((w) -> results.push(w))

      vv.set(2)
      vv.set(3)
      v.set(2)
      results.should.eql([ 3 ])

  describe 'side effect management', ->
    it 'should not re-execute orphaned propagations', ->
      v = new Varying()

      # first, set up a reaction that causes a cyclic set.
      hasRetriggered = false
      v.reactLater(-> v.set(2) unless hasRetriggered)

      # next, set up a reaction later in the chain. count its executions.
      runCount = 0
      v.reactLater(-> runCount += 1)

      # now go.
      v.set(1)
      runCount.should.equal(1)

    it 'should provide the right value in a cyclic set', ->
      v = new Varying()

      hasRetriggered = false
      v.reactLater(-> v.set(2) unless hasRetriggered)

      result = null
      v.reactLater((x) -> result = x)

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

      it 'should callback with a mapped value when reactLater is called', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.pure(((x, y) -> x + y), va, vb)

        result = 0
        m.reactLater((x) -> result = x)

        va.set(3)
        result.should.equal(5)

        vb.set(4)
        result.should.equal(7)

      it 'should callback immediately with a mapped value when react is called', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.pure(((x, y) -> x + y), va, vb)

        result = 0
        m.react((x) -> result = x)
        result.should.equal(3)

        vb.set(4)
        result.should.equal(5)

      it 'should not flatten on react', ->
        m = Varying.pure(((x, y) -> new Varying(x + y)), new Varying(1), new Varying(2))

        result = null
        m.react((x) -> result = x)

        result.should.be.an.instanceof(Varying)
        result.get().should.equal(3)

      it 'should bind this to the Observation within the handler', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.pure(((x, y) -> new Varying(x + y)), va, vb)
        t = null

        r = m.react(-> t = this)
        r.should.equal(t)

        va.set(2)
        r.should.equal(t)

      it 'should cease reacting on stopped handlers', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.pure(((x, y) -> new Varying(x + y)), va, vb)

        runCount = 0
        r = m.reactLater((x) -> runCount += 1)
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

        m.react(->).stop()

        countObservers(va).should.equal(0)
        countObservers(vb).should.equal(0)

      it 'should bind correctly when reacted multiple times off the root', ->
        va = new Varying(2)
        vb = new Varying(2)
        vf = va.flatMap((x) -> vb.map((y) -> x * y))

        results = []
        vf.react((z) -> results.push(1, z))
        vf.react((z) -> results.push(2, z))

        vb.set(4)
        va.set(3)

        results.should.eql([ 1, 4, 2, 4, 1, 8, 2, 8, 1, 12, 2, 12 ])

    describe 'flatMapAll', ->
      it 'should flatten on get', ->
        Varying.flatMapAll(((x, y) -> new Varying(x + y)), new Varying(1), new Varying(2)).get().should.be.equal(3)

      it 'should callback with a flatmapped value when react is called', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.flatMapAll(((x, y) -> new Varying(x + y)), va, vb)

        result = 0
        m.reactLater((x) -> result = x)

        va.set(3)
        result.should.equal(5)

        vb.set(4)
        result.should.equal(7)

      it 'should callback immediately with a flatmapped value when react is called', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.flatMapAll(((x, y) -> new Varying(x + y)), va, vb)

        result = 0
        m.react((x) -> result = x)
        result.should.equal(3)

        vb.set(4)
        result.should.equal(5)

      it 'should flatten on react', ->
        va = new Varying(1)
        vb = new Varying(2)
        m = Varying.flatMapAll(((x, y) -> new Varying(x + y)), va, vb)

        result = null
        m.react((x) -> result = x)

        result.should.equal(3)

      it 'should re-react to an inner varying after flatMapping', ->
        va = new Varying(1)
        vb = new Varying(2)
        vz = null
        m = Varying.flatMapAll(((x, y) -> vz = new Varying(x + y)), va, vb)

        result = null
        m.react((x) -> result = x)

        va.set(3)
        result.should.equal(5)

        vz.set(6)
        result.should.equal(6)

      it 'should re-react to an inner varying set before flatMapping', ->
        vz = null
        m = Varying.flatMapAll(((x, y) -> vz = new Varying(x + y)), new Varying(1), new Varying(2))

        result = null
        m.react((x) -> result = x)
        result.should.equal(3)

        vz.set(4)
        result.should.equal(4)

      it 'should cease reacting to an inner varying once it is gone', ->
        va = new Varying(1)
        vb = new Varying(2)
        vx = null
        m = Varying.flatMapAll(((x, y) -> vx = new Varying(x + y)), va, vb)

        result = null
        m.react((x) -> result = x)

        va.set(1)
        vz = vx

        va.set(3)
        vz.set(4)
        result.should.equal(5)

  describe 'lift', ->
    it 'should take a pure function and arguments and return a mapped varying', ->
      va = new Varying(2)
      vb = new Varying(7)
      fm = Varying.lift((x, y) -> x * y)
      vc = fm(va, vb)

      result = null
      vc.react((x) -> result = x)

      result.should.equal(14)
      vb.set(5)
      result.should.equal(10)
      va.set(3)
      result.should.equal(15)

    it 'should not flatten the result', ->
      va = new Varying(2)
      vb = new Varying(7)
      fm = Varying.lift((x, y) -> new Varying(x * y))
      vc = fm(va, vb)

      result = null
      vc.react((x) -> result = x)
      result.isVarying.should.equal(true)
      result.get().should.equal(14)

  describe 'pipe chaining', ->
    it 'should call the given function with itself', ->
      result = null
      pipeFunc = (x) -> result = x

      v = new Varying(1)
      v.pipe(pipeFunc)
      result.should.equal(v)

  describe 'managed resources', ->
    it 'should call each resource generator and pass them to the computation generator upon react', ->
      results = null
      v = Varying.managed((-> 1), (-> 2), (-> 3), (xs...) -> results = xs)
      should(results).equal(null)
      v.reactLater(->)
      results.should.eql([ 1, 2, 3 ])

    it 'should use the result of the computation generator as its own result', ->
      vi = new Varying(0)
      v = Varying.managed(-> vi)

      results = []
      vd = v.react((x) -> results.push(x))
      vi.set(2)
      vi.set(4)
      results.should.eql([ 0, 2, 4 ])

    it 'should not create resources if they already exist', ->
      count = 0
      track = (f) -> -> count++; f()
      v = Varying.managed(track(-> 1), track(-> 2), (x, y) -> new Varying(x + y))
      count.should.equal(0)
      v.react(->)
      count.should.equal(2)
      v.react(->)
      count.should.equal(2)

    it 'should destroy resources if no longer needed', ->
      destroyed = 0
      destructible = -> { destroy: -> destroyed++ }
      v = Varying.managed(destructible, destructible, -> new Varying())
      destroyed.should.equal(0)
      vda = v.react(->)
      vdb = v.react(->)
      destroyed.should.equal(0)
      vda.stop()
      destroyed.should.equal(0)
      vdb.stop()
      destroyed.should.equal(2)

    it 'should recreate resources when needed again', ->
      count = 0
      track = (f) -> -> count++; { valueOf: f, destroy: (->) }
      v = Varying.managed(track(-> 1), track(-> 2), (x, y) -> new Varying(x + y))
      vda = v.react(->)
      vdb = v.react(->)
      count.should.equal(2)
      vda.stop()
      vdb.stop()
      count.should.equal(2)
      v.react(->)
      count.should.equal(4)

    it 'should get value from active managed varyings', ->
      v = Varying.managed((-> 1), (-> 2), (-> 3), (x, y, z) -> new Varying(x + y + z))
      v.react(->)
      v.get().should.equal(6)

    it 'should get value from dormant managed varyings, and clean up', ->
      destroyed = 0
      destructible = (f) -> -> { valueOf: f, destroy: -> destroyed++ }
      v = Varying.managed(destructible(-> 1), destructible(-> 2), (x, y) -> new Varying(x + y))
      v.get().should.equal(3)
      destroyed.should.equal(2)

