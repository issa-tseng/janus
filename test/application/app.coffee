{ App } = require('../../lib/application/app')
{ Base } = require('../../lib/core/base')
{ Varying } = require('../../lib/core/varying')

describe 'base App model', ->
  describe 'library instantiation', ->
    it 'should preserve default library instance constancy', ->
      app = new App()
      app.get('views').register(String, 1)
      app.get('views').get('').should.equal(1)

      app.get('resolvers').register(String, 1)
      app.get('resolvers').get('').should.equal(1)

  describe 'view handling', ->
    it 'should come with a view library by default', ->
      (new App()).get('views').isLibrary.should.equal(true)

    it 'should pass the subject and criteria to the library', ->
      subject = criteria = null
      library = { get: (x, y) -> subject = x; criteria = y; null }
      (new App( views: library )).view(12, 24)
      subject.should.equal(12)
      criteria.should.equal(24)

    it 'should instantiate a class if returned by the library', ->
      class A
      (new App( views: { get: -> A } )).view().should.be.an.instanceof(A)

    it 'should pass subject and options to the class when instantiated', ->
      class A
        constructor: (@subject, @options) ->

      view = (new App( views: { get: -> A } )).view(12, null, { test: 24 })
      view.subject.should.equal(12)
      view.options.test.should.equal(24)

    it 'should inject itself as options.app into the instantiated view', ->
      class A
        constructor: (_, @options) ->

      app = new App( views: { get: -> A } )
      view = app.view(12, null, { test: 24 })
      view.options.test.should.equal(24)
      view.options.app.should.equal(app)

    it 'should not override an explicit options.app', ->
      class A
        constructor: (_, @options) ->

      view = (new App( views: { get: -> A } )).view(12, null, { app: 24 })
      view.options.app.should.equal(24)

    it 'should emit an event when a view is vended', ->
      results = []
      class A
      app = new App( views: { get: (x) -> A if x is true } )
      app.on('createdView', (x) -> results.push(x))

      app.view(false)
      results.length.should.equal(0)

      app.view(true)
      results.length.should.equal(1)
      results[0].should.be.an.instanceof(A)

    describe 'resolution', ->
      it 'should call autoresolve if it exists on the subject', ->
        called = null
        class A
        app = new App( views: { get: -> A } )
        app.view({ autoResolveWith: (x) -> called = x })
        called.should.equal(app)

      it 'should manually resolve requested attributes from viewclass def', ->
        resolvedWith = attr = null
        subject = {
          attribute: (key) ->
            attr = key
            { isReference: true, resolveWith: (x) -> resolvedWith = x }
        }
        class A
          resolve: 'test'
        app = new App( views: { get: -> A } )
        app.view(subject)
        attr.should.equal('test')
        resolvedWith.should.equal(app)

      it 'should manually resolve requested attributes from render options', ->
        resolvedWith = attr = null
        subject = {
          attribute: (key) ->
            attr = key
            { isReference: true, resolveWith: (x) -> resolvedWith = x }
        }
        class A
        app = new App( views: { get: -> A } )
        app.view(subject, null, { resolve: 'test' })
        attr.should.equal('test')
        resolvedWith.should.equal(app)

      it 'should resolve multiple requested attributes', ->
        attrs = []
        resolves = 0
        subject = {
          attribute: (key) ->
            attrs.push(key)
            { isReference: true, resolveWith: -> resolves += 1 }
        }
        class A
        app = new App( views: { get: -> A } )
        app.view(subject, null, { resolve: [ 'one', 'two' ] })
        attrs.should.eql([ 'one', 'two' ])
        resolves.should.equal(2)

      it 'should have the view react to requested attributes', ->
        watches = {}
        subject = {
          attribute: (key) -> {}
          watch: (key) -> watches[key] ?= new Varying()
        }

        class A extends Base
        app = new App( views: { get: -> A } )
        view = app.view(subject, null, { resolve: 'test' })
        subject.watch('test').refCount().get().should.equal(1)

        view.destroy()
        subject.watch('test').refCount().get().should.equal(0)

      it 'should not resolve non-references', ->
        called = false
        subject = { attribute: -> { resolveWith: -> called = true } }
        class A
        app = new App( views: { get: -> A } )
        app.view(subject, null, { resolve: 'test' })
        called.should.equal(false)

      it 'should not try to resolve if the subject cannot', ->
        should.doesNotThrow(->
          class A
          app = new App( views: { get: -> A } )
          app.view({}, null, { resolve: 'test' })
        )

  describe 'request resolving', ->
    it 'should do nothing if a non-request is given', ->
      should.doesNotThrow(->
        should.not.exist((new App()).resolve(null))
        should.not.exist((new App()).resolve({}))
      )

    it 'should rely on the resolver to resolve the request', ->
      result = null
      class TestApp extends App
        resolver: -> (x) -> result = x

      (new TestApp()).resolve({ isRequest: true, test: 42 })
      result.should.eql({ isRequest: true, test: 42 })

    it 'should cache the given resolver', ->
      count = 0
      results = []
      class TestApp extends App
        resolver: ->
          thisCount = ++count
          -> results.push(thisCount)

      app = new TestApp()
      app.resolve({ isRequest: true })
      app.resolve({ isRequest: true })
      results.should.eql([ 1, 1 ])

    it 'should return the value if successful', ->
      class TestApp extends App
        resolver: -> -> 42
      (new TestApp()).resolve({ isRequest: true }).should.equal(42)

    it 'should return nothing if unsuccessful', ->
      class TestApp extends App
        resolver: -> ->
      should.not.exist((new TestApp()).resolve({ isRequest: true }))

    it 'should emit an event if successful', ->
      req = res = null
      class TestApp extends App
        resolver: -> -> 42
      app = new TestApp()
      app.on('resolvedRequest', (x, y) -> req = x; res = y)
      app.resolve({ isRequest: true, test: 8 })
      req.test.should.equal(8)
      res.should.equal(42)

  describe 'default resolver', ->
    it 'should come with a resolver library by default', ->
      (new App()).get('resolvers').isLibrary.should.equal(true)

    it 'should return a resolver', ->
      (new App()).resolver().should.be.a.Function()

    it 'should ask the resolver library for a resolver', ->
      subject = null
      (new App( resolvers: { get: (x) -> subject = x; null } )).resolver()(42)
      subject.should.equal(42)

