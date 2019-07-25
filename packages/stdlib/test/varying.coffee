should = require('should')

{ Varying } = require('janus')
{ sticky, debounce, throttle, filter, zipSequential, fromEvent, fromEvents } = require('../lib/varying')

wait = (time, f) -> setTimeout(f, time)

describe 'varying utils', ->
  describe 'managed observation', ->
    it 'should stop its inner observation if destroyed', ->
      started = stopped = false
      dummyVarying = { react: (-> started = true; { stop: (-> stopped = true) }), get: (->) }
      v = sticky(null, dummyVarying)
      o = v.react(->)
      started.should.equal(true)
      stopped.should.equal(false)
      o.stop()
      stopped.should.equal(true)

  describe 'sticky', ->
    it 'should return a varying', ->
      sticky(null, new Varying()).should.be.an.instanceof(Varying)

    it 'should by default pass values through (instantly)', ->
      results = []
      inner = new Varying(0)
      outer = sticky(null, inner)
      outer.react((x) -> results.push(x))

      results.should.eql([ 0 ])
      inner.set(1)
      results.should.eql([ 0, 1 ])
      inner.set(2)
      results.should.eql([ 0, 1, 2 ])

    it 'should hold on to values as configured', (done) ->
      results = []
      inner = new Varying(0)
      outer = sticky({ 1: 20 }, inner)
      outer.react((x) -> results.push(x))

      results.should.eql([ 0 ])
      inner.set(1)
      results.should.eql([ 0, 1 ])
      inner.set(2)
      results.should.eql([ 0, 1 ])
      wait(25, ->
        results.should.eql([ 0, 1, 2 ])
        done()
      )

    it 'should collapse changes during delay', (done) ->
      results = []
      inner = new Varying(0)
      outer = sticky({ 1: 20 }, inner)
      outer.react((x) -> results.push(x))

      results.should.eql([ 0 ])
      inner.set(1)
      results.should.eql([ 0, 1 ])
      inner.set(1.1)
      inner.set(1.2)
      inner.set(1.3)
      inner.set(2)
      results.should.eql([ 0, 1 ])
      wait(25, ->
        results.should.eql([ 0, 1, 2 ])
        done()
      )

    it 'should curry if given only one parameter', ->
      a = sticky(null)
      a.should.be.an.instanceof(Function)
      b = a(new Varying())
      b.should.be.an.instanceof(Varying)

  describe 'debounce', ->
    it 'should collapse values up through cooldown', (done) ->
      results = []
      inner = new Varying(0)
      outer = debounce(10, inner)
      outer.react((x) -> results.push(x))

      results.should.eql([ 0 ])
      inner.set(1)
      inner.set(2)
      results.should.eql([ 0 ])

      wait(20, ->
        results.should.eql([ 0, 2 ])
        done()
      )

    it 'should push cooldown for each change', (done) ->
      results = []
      inner = new Varying(0)
      outer = debounce(20, inner)
      outer.react((x) -> results.push(x))

      results.should.eql([ 0 ])
      inner.set(1)
      wait(10, ->
        results.should.eql([ 0 ])
        inner.set(2)
        wait(10, ->
          results.should.eql([ 0 ])
          inner.set(3)
          wait(25, ->
            results.should.eql([ 0, 3 ])
            done()
          )
        )
      )

    it 'should work through successive cycles', (done) ->
      results = []
      inner = new Varying(0)
      outer = debounce(5, inner)
      outer.react((x) -> results.push(x))

      inner.set(1)
      inner.set(2)
      results.should.eql([ 0 ])
      wait(10, ->
        results.should.eql([ 0, 2 ])
        inner.set(3)
        inner.set(4)
        results.should.eql([ 0, 2 ])
        wait(10, ->
          results.should.eql([ 0, 2, 4 ])
          done()
        )
      )

    it 'should curry if given only one parameter', ->
      a = debounce(20)
      a.should.be.an.instanceof(Function)
      b = a(new Varying())
      b.should.be.an.instanceof(Varying)

  describe 'throttle', ->
    it 'should set value immediately', ->
      results = []
      inner = new Varying(0)
      outer = throttle(20, inner)
      outer.react((x) -> results.push(x))

      inner.set(2)
      results.should.eql([ 0, 2 ])

    it 'should delay set within throttle zone until throttle expiration', (done) ->
      results = []
      inner = new Varying(0)
      outer = throttle(10, inner)
      outer.react((x) -> results.push(x))

      inner.set(2)
      inner.set(4)
      results.should.eql([ 0, 2 ])

      wait(15, ->
        results.should.eql([ 0, 2, 4 ])
        done()
      )

    it 'should delay multiple sets and take only the final value', (done) ->
      results = []
      inner = new Varying(0)
      outer = throttle(20, inner)
      outer.react((x) -> results.push(x))

      inner.set(2)
      inner.set(4)
      results.should.eql([ 0, 2 ])

      wait(10, ->
        inner.set(6)
        results.should.eql([ 0, 2 ])
      )
      wait(25, ->
        results.should.eql([ 0, 2, 6 ])
        done()
      )

    it 'should reset cycle once the throttle has expired', (done) ->
      results = []
      inner = new Varying(0)
      outer = throttle(10, inner)
      outer.react((x) -> results.push(x))

      inner.set(2)
      inner.set(4)
      results.should.eql([ 0, 2 ])

      wait(15, ->
        results.should.eql([ 0, 2, 4 ])

        inner.set(6)
        results.should.eql([ 0, 2, 4, 6 ])

        inner.set(8)
        results.should.eql([ 0, 2, 4, 6 ])

        wait(15, ->
          results.should.eql([ 0, 2, 4, 6, 8 ])
          done()
        )
      )

    it 'should not freeze up if the initial set does not throttle', (done) ->
      results = []
      inner = new Varying(0)
      outer = throttle(5, inner)
      outer.react((x) -> results.push(x))

      inner.set(1)
      wait(10, ->
        inner.set(2)
        results.should.eql([ 0, 1, 2 ])
        done()
      )

    it 'should curry if given only one parameter', ->
      a = throttle(20)
      a.should.be.an.instanceof(Function)
      b = a(new Varying())
      b.should.be.an.instanceof(Varying)

  describe 'filter', ->
    it 'should return a varying', ->
      filter((->), new Varying()).should.be.an.instanceof(Varying)

    it 'should take an initial value if the filter accepts it', ->
      result = null
      filter((-> true), new Varying(42)).react((x) -> result = x)
      result.should.equal(42)

    it 'should not have an initial value if the filter rejects it', ->
      result = {}
      filter((-> false), new Varying(42)).react((x) -> result = x)
      (result is undefined).should.equal(true)

    it 'should pass the present value to the filter function', ->
      passed = null
      filter(((x) -> passed = x), new Varying(42)).react(->)
      passed.should.equal(42)

    it 'should passthrough only values that pass the filter', ->
      results = []
      v = new Varying(1)
      filter(((x) -> (x % 2) is 0), v).react((x) -> results.push(x))
      v.set(x) for x in [ 2, 3, 4, 5, 6 ]
      results.should.eql([ undefined, 2, 4, 6 ])

  describe 'zipSequential', ->
    it 'should return a varying', ->
      zipSequential(new Varying()).should.be.an.instanceof(Varying)

    it 'should have no initial value', ->
      result = null
      zipSequential(new Varying(42)).react((x) -> result = x)
      result.should.eql([])

    it 'should give the past two values', ->
      result = null
      source = new Varying(42)
      zipSequential(source).react((x) -> result = x)
      source.set(108)
      result.should.eql([ 42, 108 ])
      source.set(72)
      result.should.eql([ 108, 72 ])

  describe 'fromEvent binding', ->
    it 'should return a varying', ->
      fromEvent(null, null, null).should.be.an.instanceof(Varying)

    it 'should register a listener with the event name when first reacted', ->
      registered = []
      jq = { on: ((x) -> registered.push(x)) }
      v = fromEvent(jq, 'click', (->))
      v.react(->)
      v.react(->)
      registered.should.eql([ 'click' ])

    it 'should unregister a listener when stopped', ->
      unregistered = []
      jq = { on: (->), off: ((x) -> unregistered.push(x)) }
      v = fromEvent(jq, 'click', (->))
      o = v.react(->)
      unregistered.should.eql([])
      o.stop()
      unregistered.should.eql([ 'click' ])

    it 'should pass the callback event to the mapping function', ->
      event = {}
      jq = { on: ((_, f_) -> f_(event)) }

      calledWith = null
      fromEvent(jq, null, (x) -> calledWith = x).react(->)
      calledWith.should.equal(event)

    it 'should use the result of the mapping function as the value of the varying', ->
      f_ = null
      results = []
      jq = { on: ((_, x) -> f_ = x) }
      fromEvent(jq, null, ((x) -> x * 2)).react((x) -> results.push(x))

      f_(2)
      results.should.eql([ NaN, 4 ])
      f_(5)
      results.should.eql([ NaN, 4, 10 ])

    it 'should not immediately call the mapping function given immediate false', ->
      f_ = null
      results = []
      jq = { on: ((_, x) -> f_ = x) }
      fromEvent(jq, null, false, ((x) -> x * 2)).react((x) -> results.push(x))

      results.should.eql([ undefined ])
      f_(2)
      results.should.eql([ undefined, 4 ])
      f_(5)
      results.should.eql([ undefined, 4, 10 ])

    it 'should immediately call the mapping function given immediate true', ->
      extern = 0
      f_ = null
      results = []
      jq = { on: ((_, x) -> f_ = x) }
      fromEvent(jq, null, true, (-> extern)).react((x) -> results.push(x))

      results.should.eql([ 0 ])
      extern = 1
      f_()
      results.should.eql([ 0, 1 ])
      extern = 2
      f_()
      results.should.eql([ 0, 1, 2 ])

  describe 'fromEvents binding', ->
    it 'should set the correct initial value', ->
      jq = { on: (->) }
      fromEvents(jq, 42, {}).get().should.equal(42)

      results = []
      fromEvents(jq, 42, {}).react((x) -> results.push(x))
      results.should.eql([ 42 ])

    it 'should listen to the correct events', ->
      listened = []
      jq = { on: ((event) -> listened.push(event)) }

      fromEvents(jq, null, { mousedown: 1, mouseup: 2 }).react(->)
      listened.should.eql([ 'mousedown', 'mouseup' ])

    it 'should hold the correct value after each event', ->
      jq = { listeners: {}, on: ((event, handler) -> this.listeners[event] = handler) }
      results = []
      fromEvents(jq, 0, { mousedown: 1, mouseup: 2 }).react((x) -> results.push(x))

      jq.listeners['mousedown']({ type: 'mousedown' })
      jq.listeners['mousedown']({ type: 'mousedown' })
      jq.listeners['mouseup']({ type: 'mouseup' })
      jq.listeners['mousedown']({ type: 'mousedown' })

      results.should.eql([ 0, 1, 2, 1 ])

    it 'should unregister all listeners on destruction', ->
      unlistened = []
      jq = { on: (->), off: ((event) -> unlistened.push(event)) }
      fromEvents(jq, 0, { mousedown: 1, mouseup: 2 }).react().stop()
      unlistened.should.eql([ 'mousedown', 'mouseup' ])

