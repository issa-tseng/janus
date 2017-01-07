should = require('should')
{ Base } = require('../../lib/core/base')

describe 'base', ->
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

