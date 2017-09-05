should = require('should')
{ Base } = require('../../lib/core/base')
{ Varying } = require('../../lib/core/varying')

describe 'base', ->
  describe 'events', ->
    it 'should listen to another object', ->
      a = new Base()
      b = new Base()

      called = null
      a.listenTo(b, 'testevent', (x) -> called = x)
      b.emit('testevent', 3)
      called.should.equal(3)

    it 'should unlisten to all events of another object', ->
      a = new Base()
      b = new Base()

      called = null
      a.listenTo(b, 'testevent1', (x) -> called = x)
      a.listenTo(b, 'testevent2', (x) -> called = x)
      a.listenTo(b, 'testevent3', (x) -> called = x)

      b.emit('testevent3', 3)
      called.should.equal(3)

      a.unlistenTo(b)

      b.emit('testevent1', 42)
      b.emit('testevent2', 42)
      b.emit('testevent3', 42)
      called.should.equal(3)

  describe 'reactions', ->
    it 'should react to a Varying', ->
      a = new Base()
      v = new Varying(2)

      result = null
      a.reactTo(v, (x) -> result = x)

      result.should.equal(2)
      v.refCount().get().should.equal(1)

    it 'should reactLater to a Varying', ->
      a = new Base()
      v = new Varying(2)

      result = null
      a.reactLaterTo(v, (x) -> result = x)
      should(result).equal(null)

      v.set(3)
      result.should.equal(3)

      v.refCount().get().should.equal(1)

    it 'should cease reacting upon destruction', ->
      a = new Base()
      v = new Varying(2)

      result = null
      a.reactTo(v, (x) -> result = x)
      a.reactLaterTo(v, (x) -> result = x)

      a.destroy()
      v.refCount().get().should.equal(0)
      v.set(3)
      result.should.equal(2)

  describe 'lifecycle', ->
    it 'should emit a destroying event upon destruction', ->
      called = false
      b = new Base()
      b.on('destroying', -> called = true)
      b.destroy()
      called.should.equal(true)

    it 'should remove all incoming listeners upon destruction', ->
      a = new Base()
      b = new Base()

      called = null
      a.listenTo(b, 'testevent1', (x) -> called = x)
      a.listenTo(b, 'testevent2', (x) -> called = x)
      a.listenTo(b, 'testevent3', (x) -> called = x)

      b.destroy()

      b.emit('testevent1', 42)
      b.emit('testevent2', 42)
      b.emit('testevent3', 42)
      should(called).equal(null)

    it 'should remove all outbound listeners upon destruction', ->
      a = new Base()
      b = new Base()

      called = null
      a.listenTo(b, 'testevent1', (x) -> called = x)
      a.listenTo(b, 'testevent2', (x) -> called = x)
      a.listenTo(b, 'testevent3', (x) -> called = x)

      a.destroy()

      b.emit('testevent1', 42)
      b.emit('testevent2', 42)
      b.emit('testevent3', 42)
      should(called).equal(null)

    it 'should destroy as appropriate when bound with destroyWith', ->
      a = new Base()
      b = new Base()

      called = false
      a.destroyWith(b)
      a.on('destroying', -> called = true)
      b.destroy()
      called.should.equal(true)

  describe 'managed', ->
    it 'should create the resource in question when called', ->
      r = { on: (->) }
      m = Base.managed(-> r)
      m().should.equal(r)

    it 'should return the same resource to multiple callees', ->
      i = 0
      m = Base.managed(-> { value: ++i, on: (->), tap: (-> this) })
      m().value.should.equal(1)
      m().value.should.equal(1)

    it 'should not destroy the object while there are still dependent resoures', ->
      destroyed = false
      m = Base.managed(-> (new Base()).on('destroying', -> destroyed = true))
      m()
      m().destroy()
      destroyed.should.equal(false)

    it 'should destroy the object once all dependencies are gone', ->
      destroyed = false
      m = Base.managed(-> (new Base()).on('destroying', -> destroyed = true))
      x = m()
      m().destroy()
      x.destroy()
      destroyed.should.equal(true)

    it 'should vend a new instance if the old resource is destroyed', ->
      created = 0
      m = Base.managed(->
        created++
        new Base()
      )

      x = m()
      m().destroy()
      x.destroy()
      created.should.equal(1)
      m()
      created.should.equal(2)

