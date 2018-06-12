should = require('should')

from = require('../../lib/core/from')
types = require('../../lib/util/types')

Model = require('../../lib/model/model').Model
attributes = require('../../lib/model/attribute')
{ attribute, bind, issue, transient, Trait } = require('../../lib/model/schema')
dfault = require('../../lib/model/schema')['default'] # silly coffeescript

Varying = require('../../lib/core/varying').Varying
{ List } = require('../../lib/collection/list')
{ Collection } = require('../../lib/collection/collection')

describe 'Model', ->
  describe 'core', ->
    it 'should construct', ->
      (new Model()).should.be.an.instanceof(Model)

    it 'should construct with a data bag', ->
      (new Model( test: 'attr' )).data.test.should.equal('attr')

    it 'should call preinitialize before data is populated', ->
      result = -1
      class TestModel extends Model
        _preinitialize: -> result = this.get('a')

      new TestModel({ a: 42 })
      should(result).equal(null)

    it 'should call initialize after data is populated', ->
      result = -1
      class TestModel extends Model
        _initialize: -> result = this.get('a')

      new TestModel({ a: 42 })
      result.should.equal(42)

  describe 'attribute get', ->
    it 'should return the default value if defined', ->
      class TestAttribute extends attributes.Attribute
        default: -> 'espresso'
      TestModel = Model.build(attribute('latte', TestAttribute))

      m = new TestModel()
      m.get('latte').should.equal('espresso')

      m2 = new TestModel({ latte: 'good' })
      m2.get('latte').should.equal('good')

    it 'should not write the default value if not specified', ->
      class TestAttribute extends attributes.Attribute
        default: -> 'espresso'
      TestModel = Model.build(attribute('latte', TestAttribute))

      m = new TestModel()
      m.get('latte').should.equal('espresso')
      m.data.should.eql({})

    it 'should write the default value if writeDefault is true', ->
      class TestAttribute extends attributes.Attribute
        default: -> 'espresso'
        writeDefault: true
      TestModel = Model.build(attribute('latte', TestAttribute))

      m = new TestModel()
      m.data.should.eql({})
      m.get('latte').should.equal('espresso')
      m.data.should.eql({ latte: 'espresso' })

  describe 'binding', ->
    describe 'application', ->
      it 'should bind one value from another', ->
        TestModel = Model.build(bind('slave', from('master')))
        model = new TestModel()
        should.not.exist(model.get('slave'))

        model.set('master', 'commander')
        model.get('slave').should.equal('commander')

      it 'should map multiple value together', ->
        TestModel = Model.build(bind('c', from('a').and('b').all.map((a, b) -> a + b)))

        model = new TestModel()
        model.set( a: 3, b: 4 )

        model.get('c').should.equal(7)

      it 'should be able to bind from a Varying', ->
        v = new Varying(2)
        TestModel = Model.build(bind('x', from.varying(-> v)))
        model = new TestModel()

        model.get('x').should.equal(2)

        v.set(4)
        model.get('x').should.equal(4)

      it 'should give model as param in Varying bind', ->
        called = false
        TestModel = Model.build(
          bind('y', from.varying((self) ->
            called = true
            self.should.be.an.instanceof(TestModel)
            new Varying()
          ))
        )

        new TestModel()
        called.should.be.true

    describe 'pointing', ->
      it 'should point dynamic varying functions', ->
        calledWith = null
        v = new Varying(1)
        TestModel = Model.build(
          bind('b', from((self) ->
            calledWith = self
            v
          ))
        )

        m = new TestModel()
        calledWith.should.equal(m)
        m.get('b').should.equal(1)

        v.set(2)
        m.get('b').should.equal(2)

      it 'should point dynamic key names', ->
        TestModel = Model.build(bind('b', from('a')))

        m = new TestModel()
        m.set('a', 1)
        m.get('b').should.equal(1)
        m.set('a', 2)
        m.get('b').should.equal(2)

      it 'should point dynamic other objects', ->
        TestModel = Model.build(bind('b', from(42)))

        m = new TestModel()
        m.get('b').should.equal(42)

      it 'should point watch key names', ->
        TestModel = Model.build(bind('b', from.watch('a')))

        m = new TestModel()
        m.set('a', 1)
        m.get('b').should.equal(1)
        m.set('a', 2)
        m.get('b').should.equal(2)

      it 'should not point resolve names by default', ->
        TestModel = Model.build(bind('b', from.resolve('a')))

        m = new TestModel()
        m.get('b').type.should.equal('resolve')

      it 'should point attribute objects', ->
        TestModel = Model.build(
          attribute('a', attributes.Number)
          bind('b', from.attribute('a'))
        )

        m = new TestModel()
        m.get('b').should.equal(m.attribute('a'))

      it 'should point explicit varying functions', ->
        calledWith = null
        v = new Varying(1)
        TestModel = Model.build(
          bind('b', from.varying((self) ->
            calledWith = self
            v
          ))
        )

        m = new TestModel()
        calledWith.should.equal(m)
        m.get('b').should.equal(1)

        v.set(2)
        m.get('b').should.equal(2)

      it 'should not point apps by default', ->
        TestModel = Model.build(bind('b', from.app()))

        m = new TestModel()
        m.get('b').type.should.equal('app')

      it 'should point apps if given', ->
        app = {}
        m = new Model()
        Model.point(from.default.app(), m, app).get().should.equal(app)

      it 'should point into app subkeys if given', ->
        resolvedWith = null
        app = { resolve: (x) -> resolvedWith = x; 'resolved!' }
        m = new Model()
        Model.point(from.default.app('test'), m, app).should.equal('resolved!')
        resolvedWith.should.equal('test')

      it 'should point self by function', ->
        calledWith = null
        TestModel = Model.build(bind('b', from.self((x) -> calledWith = x; 42)))

        m = new TestModel()
        calledWith.should.equal(m)
        m.get('b').should.equal(42)

      it 'should point self statically', ->
        TestModel = Model.build(bind('b', from.self()))

        m = new TestModel()
        m.get('b').should.equal(m)

    describe 'classtree', ->
      it 'should not pollute across classdefs', ->
        TestA = Model.build(bind('a', from('c')))
        TestB = Model.build(bind('b', from('c')))

        a = new TestA()

        b = new TestB()
        b.set('c', 47)
        should.not.exist(b.get('a'))

      it 'should not pollute crosstree', ->
        Root = Model.build(bind('root', from('x')))
        Left = Model.build(bind('left', from('x')))
        Right = Model.build(bind('right', from('x')))

        root = new Root( x: 'root' )
        should.not.exist(root.get('left'))
        should.not.exist(root.get('right'))

        left = new Left( x: 'left' )
        should.not.exist(left.get('right'))

        right = new Right( x: 'right' )
        should.not.exist(right.get('left'))

      it 'should extend downtree', ->
        Root = Model.build(bind('root', from('x')))
        Child = Root.build(bind('child', from('x')))

        child = new Child( x: 'test' )
        child.get('root').should.equal('test')
        child.get('child').should.equal('test')

      it 'should allow child bind to override parent', ->
        Root = Model.build(bind('contend', from('x')))
        Child = Root.build(bind('contend', from('y')))

        (new Child( x: 1, y: 2 )).get('contend').should.equal(2)

    describe 'shadowing', ->
      it 'should not propagate parent bound values', ->
        TestModel = Model.build(bind('b', from('a')))

        x = new TestModel( a: 2 )
        y = x.shadow()
        y.set('a', 3)
        x.set('a', 1)
        y.get('b').should.equal(3)

  describe 'defined attributes', ->
    it 'should be definable and fetchable', ->
      TestModel = Model.build(attribute('attr', attributes.Text))

      (new TestModel()).attribute('attr').should.be.an.instanceof(attributes.Text)

    it 'should inherit down the classtree', ->
      Root = Model.build(attribute('attr', attributes.Number))
      class Child extends Root

      (new Child()).attribute('attr').should.be.an.instanceof(attributes.Number)

    it 'should not pollute across classdefs', ->
      A = Model.build(attribute('a', attributes.Number))
      B = Model.build(attribute('b', attributes.Number))

      should.not.exist((new A()).attribute('b'))
      should.not.exist((new B()).attribute('a'))

    it 'should memoize results', ->
      TestModel = Model.build(attribute('attr', attributes.Boolean))

      model = new TestModel()
      model.attribute('attr').should.equal(model.attribute('attr'))

    it 'should allow default shortcut for defining a default value', ->
      TestModel = Model.build(dfault('test', 42))
      (new TestModel()).get('test').should.equal(42)

    it 'should take a function with default for defining a default value', ->
      i = 0
      TestModel = Model.build(dfault('test', -> ++i))
      (new TestModel()).get('test').should.equal(1)
      (new TestModel()).get('test').should.equal(2)

    it 'should allow for the attribute class to be defined with @default', ->
      TestModel = Model.build(dfault('test', 42, attributes.Number))
      (new TestModel()).attribute('test').should.be.an.instanceof(attributes.Number)

    it 'should allow @transient shortcut to declare an attribute transient', ->
      TestModel = Model.build(transient('tempkey'))
      (new TestModel()).attribute('tempkey').transient.should.equal(true)

  describe 'resolving', ->
    it 'should behave like watch for non-reference attributes', ->
      values = []
      TestModel = Model.build(attribute('a', attributes.Number))

      m = new TestModel()
      m.resolve('a', null).react((x) -> values.push(x))

      m.set('a', 2)
      values.should.eql([ null, 2 ])

    it 'should do nothing if no attribute is declared', ->
      value = -1
      m = new Model()
      m.resolve('a', null).react((x) -> value = x)
      should(value).equal(null)

    it 'should return the proper value for a resolved reference attribute', ->
      values = []

      TestModel = Model.build(attribute('a', attributes.Reference))

      m = new TestModel()
      m.set('a', 1)

      m.resolve('a', null).react((x) -> values.push(x))
      m.set('a', 2)
      values.should.eql([ 1, 2 ])

    it 'should point the reference request from the store library given an app', ->
      ourRequest = new Varying()
      givenRequest = null
      app = { vendStore: ((x) -> givenRequest = x; { handle: (->), destroy: (->) }) }
      TestModel = Model.build(
        attribute('a', class extends attributes.Reference
          request: -> ourRequest
        )
      )

      m = new TestModel()
      v = m.resolve('a', app)
      should(givenRequest).equal(null) # doesn't actually point until reacted.
      v.react(->)
      givenRequest.should.equal(ourRequest)

    it 'calls handle on the store that handles the request', ->
      called = false
      app = { vendStore: (x) -> { handle: (-> called = true), destroy: (->) } }
      TestModel = Model.build(
        attribute('a', class extends attributes.Reference
          request: -> new Varying()
        )
      )

      m = new TestModel()
      v = m.resolve('a', app)
      called.should.equal(false) # doesn't actually point until reacted.
      v.react(->)
      called.should.equal(true)

    it 'fails gracefully if no store is found to handle the request', ->
      app = { vendStore: -> null }
      TestModel = Model.build(
        attribute('a', class extends attributes.Reference
          request: -> new Varying()
        )
      )

      m = new TestModel()
      v = m.resolve('a', app)
      v.react(->)
      should(v.get()).equal(undefined)

    it 'destroys the store if the refcount drops to zero', ->
      destroyed = 0
      app = { vendStore: -> { handle: (->), destroy: (-> destroyed++) } }
      TestModel = Model.build(
        attribute('a', class extends attributes.Reference
          request: -> new Varying()
        )
      )

      m = new TestModel()
      v = m.resolve('a', app)
      vda = v.react(->)
      vdb = v.react(->)
      destroyed.should.equal(0)
      vda.stop()
      vdb.stop()
      destroyed.should.equal(1)

    it 'immediately calls handle on the store that handles the request given resolveNow', ->
      called = false
      app = { vendStore: (x) -> { handle: (-> called = true), destroy: (->) } }
      TestModel = Model.build(
        attribute('a', class extends attributes.Reference
          request: -> new Varying()
        )
      )

      m = new TestModel()
      m.resolveNow('a', app)
      called.should.equal(true)

    it 'relinquishes its hold on the resolveNow`d request if it reaches completion', (done) ->
      called = false
      request = null
      app = { vendStore: (x) -> { handle: (-> request = x), destroy: (-> called = true) } }
      TestModel = Model.build(
        attribute('a', class extends attributes.Reference
          request: -> new Varying()
        )
      )

      m = new TestModel()
      m.resolveNow('a', app)
      request.set(types.result.failure(47))
      setTimeout((->
        called.should.equal(true)
        done()
      ), 0)

    it 'gives the request\'s inner value as its own', ->
      value = null
      request = new Varying()
      app = { vendStore: (x) -> { handle: (->), destroy: (->) } }
      TestModel = Model.build(
        attribute('a', class extends attributes.Reference
          request: -> request
        )
      )

      m = new TestModel()
      m.resolve('a', app).react((x) -> value = x)
      should(value).equal(undefined)

      request.set(types.result.progress(26))
      value.type.should.equal('progress')
      value.value.should.equal(26)

      request.set(types.result.success())
      value.type.should.equal('success')
      value.value.should.be.an.instanceof(Model)

    it 'deserializes with the attribute\'s declared contained class deserializer', ->
      called = false
      value = null
      request = new Varying()
      app = { vendStore: (x) -> { handle: (->), destroy: (->) } }
      class TestInner extends Model
        @deserialize: (data) ->
          called = true
          super(data)
      TestModel = Model.build(
        attribute('a', class extends attributes.Reference
          @contains: TestInner
          request: -> request
        )
      )

      m = new TestModel()
      m.resolve('a', app).react((x) -> value = x)

      request.set(types.result.success({ a: 42 }))
      called.should.equal(true)
      value.type.should.equal('success')
      value.value.get('a').should.equal(42)

    it 'resolves correctly when given a value in handle()', ->
      value = null
      app = { vendStore: (x) -> { handle: (-> x.set(types.result.success({ a: 42 }))), destroy: (->) } }
      TestModel = Model.build(
        attribute('a', class extends attributes.Reference
          request: -> new Varying()
        )
      )

      m = new TestModel()
      m.resolve('a', app).react((x) -> value = x)
      value.type.should.equal('success')
      value.value.get('a').should.equal(42)

    it 'sets a successful value concretely if found', ->
      value = null
      request = new Varying()
      app = { vendStore: (x) -> { handle: (->), destroy: (->) } }
      TestModel = Model.build(
        attribute('a', class extends attributes.Reference
          request: -> request
        )
      )

      m = new TestModel()
      m.resolve('a', app).react(->)
      should(m.get('a')).equal(null)

      request.set(types.result.progress(26))
      should(m.get('a')).equal(null)

      request.set(types.result.success({ b: 42 }))
      m.get('a').should.be.an.instanceof(Model)
      m.get('a').get('b').should.equal(42)

    # TODO: many noncovered methods

  describe 'issues', ->
    it 'should return an empty list by default', ->
      issues = (new Model()).issues()
      issues.should.be.an.instanceof(Collection)
      issues.list.length.should.equal(0)

    it 'should contain issues from the Model level', ->
      TestModel = Model.build(
        issue(from(types.validity.valid()))
        issue(from(types.validity.error()))
      )

      model = new TestModel()
      model.issues().list.length.should.equal(2)

  describe 'validity', ->
    it 'should return true if no active issues exist', ->
      v1 = new Varying(types.validity.valid())
      v2 = new Varying(types.validity.valid())
      TestModel = Model.build(
        issue(from(v1))
        issue(from(v2))
      )

      model = new TestModel()
      model.valid().get().should.equal(true)

    it 'should return false if one or more active issues exist', ->
      v1 = new Varying(types.validity.error())
      v2 = new Varying(types.validity.error())
      TestModel = Model.build(
        issue(from(v1))
        issue(from(v2))
      )

      model = new TestModel()
      model.valid().get().should.equal(false)

      v1.set(types.validity.valid())
      model.valid().get().should.equal(false)

      v2.set(types.validity.valid())
      model.valid().get().should.equal(true)

  describe 'trait bundling', ->
    it 'should receive and apply a set of schema definitions', ->
      TestTrait = Trait(
        bind('a', from('b'))
        bind('x', from('y'))
      )
      TestModel = Model.build(TestTrait)

      m = new TestModel( b: 2, y: 4 )
      m.get('a').should.equal(2)
      m.get('x').should.equal(4)

    it 'should work alongside direct definitions', ->
      TestTrait = Trait(
        bind('a', from('b'))
      )
      TestModel = Model.build(
        TestTrait
        bind('x', from('y'))
      )

      m = new TestModel( b: 2, y: 4 )
      m.get('a').should.equal(2)
      m.get('x').should.equal(4)

    it 'should nest', ->
      RootTrait = Trait(
        bind('a', from('b'))
      )
      ChildTrait = Trait(
        RootTrait
        bind('x', from('y'))
      )
      TestModel = Model.build(ChildTrait)

      m = new TestModel( b: 2, y: 4 )
      m.get('a').should.equal(2)
      m.get('x').should.equal(4)

  describe 'deserialization', ->
    it 'should store the given data into the correct places', ->
      Model.deserialize( a: { b: 1, c: 2 }, d: 3 ).data.should.eql({ a: { b: 1, c: 2 }, d: 3 })

    it 'should rely on provided attributes to deserialize if given', ->
      TestModel = Model.build(
        attribute('a', class extends attributes.Attribute
          @deserialize: (x) -> "a#{x}")

        attribute('b.c', class extends attributes.Attribute
          @deserialize: (x) -> "bc#{x}")

        attribute('b.d', attributes.Attribute)

        attribute('x', class extends attributes.Attribute
          @deserialize: (x) -> "x#{x}")
      )

      TestModel.deserialize( a: 1, b: { c: 2, d: 3 } ).data.should.eql({ a: 'a1', b: { c: 'bc2', d: 3 } })

