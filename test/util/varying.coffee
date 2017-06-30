should = require('should')

{ Varying } = require('janus')
{ sticky, debounce, fromEvent, fromEventNow } = require('../../lib/util/varying')

wait = (time, f) -> setTimeout(f, time)

describe 'varying utils', ->
  describe 'managed observation', ->
    it 'should stop its inner observation if destroyed', ->
      started = stopped = false
      dummyVarying = { reactNow: (-> started = true; { stop: (-> stopped = true) }), get: (->) } 
      v = sticky(dummyVarying)
      o = v.reactNow(->)
      started.should.equal(true)
      stopped.should.equal(false)
      o.stop()
      stopped.should.equal(true)

  describe 'sticky', ->
    it 'should return a varying', ->
      sticky(new Varying()).should.be.an.instanceof(Varying)

    it 'should by default pass values through (instantly)', ->
      results = []
      inner = new Varying(0)
      outer = sticky(inner)
      outer.reactNow((x) -> results.push(x))

      results.should.eql([ 0 ])
      inner.set(1)
      results.should.eql([ 0, 1 ])
      inner.set(2)
      results.should.eql([ 0, 1, 2 ])

    it 'should hold on to values as configured', (done) ->
      results = []
      inner = new Varying(0)
      outer = sticky(inner, { 1: 20 })
      outer.reactNow((x) -> results.push(x))

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
      outer = sticky(inner, { 1: 20 })
      outer.reactNow((x) -> results.push(x))

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

  describe 'debounce', ->
    it 'should collapse values up through cooldown', (done) ->
      results = []
      inner = new Varying(0)
      outer = debounce(inner, 10)
      outer.reactNow((x) -> results.push(x))

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
      outer = debounce(inner, 20)
      outer.reactNow((x) -> results.push(x))

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
      outer = debounce(inner, 5)
      outer.reactNow((x) -> results.push(x))

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

  describe 'fromEvent binding', ->
    it 'should return a varying', ->
      fromEvent(null, null, null).should.be.an.instanceof(Varying)

    it 'should register a listener with the event name when first reacted', ->
      registered = []
      jq = { on: ((x) -> registered.push(x)) }
      v = fromEvent(jq, 'click', null)
      v.reactNow(->)
      v.reactNow(->)
      registered.should.eql([ 'click' ])

    it 'should unregister a listener when first reacted', ->
      unregistered = []
      jq = { on: (->), off: ((x) -> unregistered.push(x)) }
      v = fromEvent(jq, 'click', null)
      o = v.reactNow(->)
      unregistered.should.eql([])
      o.stop()
      unregistered.should.eql([ 'click' ])

    it 'should pass the callback event to the mapping function', ->
      event = {}
      jq = { on: ((_, f_) -> f_(event)) }

      calledWith = null
      fromEvent(jq, null, (x) -> calledWith = x).reactNow(->)
      calledWith.should.equal(event)

    it 'should use the result of the mapping function as the value of the varying', ->
      f_ = null
      results = []
      jq = { on: ((_, x) -> f_ = x) }
      fromEvent(jq, null, ((x) -> x * 2)).reactNow((x) -> results.push(x))

      f_(2)
      results.should.eql([ undefined, 4 ])
      f_(5)
      results.should.eql([ undefined, 4, 10 ])

    it 'should immediately call the mapping function given fromEventNow', ->
      extern = 0
      f_ = null
      results = []
      jq = { on: ((_, x) -> f_ = x) }
      fromEventNow(jq, null, (-> extern)).reactNow((x) -> results.push(x))

      results.should.eql([ 0 ])
      extern = 1
      f_()
      results.should.eql([ 0, 1 ])
      extern = 2
      f_()
      results.should.eql([ 0, 1, 2 ])

