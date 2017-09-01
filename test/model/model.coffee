should = require('should')

from = require('../../lib/core/from')
types = require('../../lib/util/types')

Model = require('../../lib/model/model').Model
Issue = require('../../lib/model/issue').Issue
attribute = require('../../lib/model/attribute')

Varying = require('../../lib/core/varying').Varying
{ List } = require('../../lib/collection/list')
{ Collection } = require('../../lib/collection/collection')

describe 'Model', ->
  describe 'core', ->
    it 'should construct', ->
      (new Model()).should.be.an.instanceof(Model)

    it 'should construct with an attribute bag', ->
      (new Model( test: 'attr' )).attributes.test.should.equal('attr')

    it 'should call preinitialize before attributes are populated', ->
      result = -1
      class TestModel extends Model
        _preinitialize: -> result = this.get('a')

      new TestModel({ a: 42 })
      should(result).equal(null)

    it 'should call initialize after attributes are populated', ->
      result = -1
      class TestModel extends Model
        _initialize: -> result = this.get('a')

      new TestModel({ a: 42 })
      result.should.equal(42)

  describe 'attribute get', ->
    it 'should return the default value if defined', ->
      class TestAttribute extends attribute.Attribute
        default: -> 'espresso'

      class TestModel extends Model
        @attribute('latte', TestAttribute)

      m = new TestModel()
      m.get('latte').should.equal('espresso')

      m2 = new TestModel({ latte: 'good' })
      m2.get('latte').should.equal('good')

    it 'should not write the default value if not specified', ->
      class TestAttribute extends attribute.Attribute
        default: -> 'espresso'

      class TestModel extends Model
        @attribute('latte', TestAttribute)

      m = new TestModel()
      m.get('latte').should.equal('espresso')
      m.attributes.should.eql({})

    it 'should write the default value if writeDefault is true', ->
      class TestAttribute extends attribute.Attribute
        default: -> 'espresso'
        writeDefault: true

      class TestModel extends Model
        @attribute('latte', TestAttribute)

      m = new TestModel()
      m.attributes.should.eql({})
      m.get('latte').should.equal('espresso')
      m.attributes.should.eql({ latte: 'espresso' })

  describe 'binding', ->
    describe 'application', ->
      it 'should bind one attribute from another', ->
        class TestModel extends Model
          @bind('slave', from('master'))

        model = new TestModel()
        should.not.exist(model.get('slave'))

        model.set('master', 'commander')
        model.get('slave').should.equal('commander')

      it 'should map multiple attributes together', ->
        class TestModel extends Model
          @bind('c', from('a').and('b').all.map((a, b) -> a + b))

        model = new TestModel()
        model.set( a: 3, b: 4 )

        model.get('c').should.equal(7)

      it 'should be able to bind from a Varying', ->
        v = new Varying(2)

        class TestModel extends Model
          @bind('x', from.varying(-> v))

        model = new TestModel()

        model.get('x').should.equal(2)

        v.set(4)
        model.get('x').should.equal(4)

      it 'should give model as param in Varying bind', ->
        called = false
        class TestModel extends Model
          @bind('y', from.varying((self) ->
            called = true
            self.should.be.an.instanceof(TestModel)
            new Varying()
          ))

        new TestModel()
        called.should.be.true

    describe 'pointing', ->
      it 'should point dynamic varying functions', ->
        calledWith = null
        v = new Varying(1)
        class TestModel extends Model
          @bind('b', from((self) ->
            calledWith = self
            v
          ))

        m = new TestModel()
        calledWith.should.equal(m)
        m.get('b').should.equal(1)

        v.set(2)
        m.get('b').should.equal(2)

      it 'should point dynamic attribute names', ->
        class TestModel extends Model
          @bind('b', from('a'))

        m = new TestModel()
        m.set('a', 1)
        m.get('b').should.equal(1)
        m.set('a', 2)
        m.get('b').should.equal(2)

      it 'should point dynamic other objects', ->
        class TestModel extends Model
          @bind('b', from(42))

        m = new TestModel()
        m.get('b').should.equal(42)

      it 'should point watch attribute names', ->
        class TestModel extends Model
          @bind('b', from.watch('a'))

        m = new TestModel()
        m.set('a', 1)
        m.get('b').should.equal(1)
        m.set('a', 2)
        m.get('b').should.equal(2)

      it 'should not point resolve attribute names by default', ->
        class TestModel extends Model
          @bind('b', from.resolve('a'))

        m = new TestModel()
        m.get('b').should.equal('resolve')

      it 'should point attribute objects', ->
        class TestModel extends Model
          @attribute('a', attribute.NumberAttribute)
          @bind('b', from.attribute('a'))

        m = new TestModel()
        m.get('b').should.equal(m.attribute('a'))

      it 'should point explicit varying functions', ->
        calledWith = null
        v = new Varying(1)
        class TestModel extends Model
          @bind('b', from.varying((self) ->
            calledWith = self
            v
          ))

        m = new TestModel()
        calledWith.should.equal(m)
        m.get('b').should.equal(1)

        v.set(2)
        m.get('b').should.equal(2)

      it 'should not point apps by default', ->
        class TestModel extends Model
          @bind('b', from.app())

        m = new TestModel()
        m.get('b').should.equal('app')

      it 'should point apps if given', ->
        app = {}
        m = new Model()
        Model._point(from.default.app(), m, app).get().should.equal(app)

      it 'should point into app subkeys if given', ->
        resolvedWith = null
        app = { resolve: (x) -> resolvedWith = x; 'resolved!' }
        m = new Model()
        Model._point(from.default.app('test'), m, app).should.equal('resolved!')
        resolvedWith.should.equal('test')

      it 'should point self by function', ->
        calledWith = null
        class TestModel extends Model
          @bind('b', from.self((x) -> calledWith = x; 42))

        m = new TestModel()
        calledWith.should.equal(m)
        m.get('b').should.equal(42)

      it 'should point self statically', ->
        class TestModel extends Model
          @bind('b', from.self())

        m = new TestModel()
        m.get('b').should.equal(m)

    describe 'classtree', ->
      it 'should not pollute across classdefs', ->
        class TestA extends Model
          @bind('a', from('c'))

        class TestB extends Model
          @bind('b', from('c'))

        a = new TestA()

        b = new TestB()
        b.set('c', 47)
        should.not.exist(b.get('a'))

      it 'should not pollute crosstree', ->
        class Root extends Model
          @bind('root', from('x'))

        class Left extends Root
          @bind('left', from('x'))

        class Right extends Root
          @bind('right', from('x'))

        root = new Root( x: 'root' )
        should.not.exist(root.get('left'))
        should.not.exist(root.get('right'))

        left = new Left( x: 'left' )
        should.not.exist(left.get('right'))

        right = new Right( x: 'right' )
        should.not.exist(right.get('left'))

      it 'should extend downtree', ->
        class Root extends Model
          @bind('root', from('x'))

        class Child extends Root
          @bind('child', from('x'))

        (new Child( x: 'test' )).get('root').should.equal('test')

      it 'should allow child bind to override parent', ->
        class Root extends Model
          @bind('contend', from('x'))

        class Child extends Root
          @bind('contend', from('y'))

        (new Child( x: 1, y: 2 )).get('contend').should.equal(2)

    describe 'shadowing', ->
      it 'should not propagate parent bound values', ->
        class TestModel extends Model
          @bind('b', from('a'))

        x = new TestModel( a: 2 )
        y = x.shadow()
        y.set('a', 3)
        x.set('a', 1)
        y.get('b').should.equal(3)

  describe 'defined attributes', ->
    it 'should be definable and fetchable', ->
      class TestModel extends Model
        @attribute('attr', attribute.TextAttribute)

      (new TestModel()).attribute('attr').should.be.an.instanceof(attribute.TextAttribute)

    it 'should inherit down the classtree', ->
      class Root extends Model
        @attribute('attr', attribute.NumberAttribute)

      class Child extends Root

      (new Child()).attribute('attr').should.be.an.instanceof(attribute.NumberAttribute)

    it 'should not pollute across classdefs', ->
      class A extends Model
        @attribute('a', attribute.NumberAttribute)

      class B extends Model
        @attribute('b', attribute.NumberAttribute)

      should.not.exist((new A()).attribute('b'))
      should.not.exist((new B()).attribute('a'))

    it 'should memoize results', ->
      class TestModel extends Model
        @attribute('attr', attribute.BooleanAttribute)

      model = new TestModel()
      model.attribute('attr').should.equal(model.attribute('attr'))

    it 'should allow @default shortcut for defining a default value', ->
      class TestModel extends Model
        @default('test', 42)
      (new TestModel()).get('test').should.equal(42)

    it 'should allow for the attribute class to be defined with @default', ->
      class TestModel extends Model
        @default('test', 42, attribute.NumberAttribute)
      (new TestModel()).attribute('test').should.be.an.instanceof(attribute.NumberAttribute)

    it 'should allow @transient shortcut to declare an attribute transient', ->
      class TestModel extends Model
        @transient('tempkey')
      (new TestModel()).attribute('tempkey').transient.should.equal(true)

  describe 'resolving', ->
    it 'should behave like watch for non-reference attributes', ->
      values = []

      class TestModel extends Model
        @attribute('a', attribute.NumberAttribute)

      m = new TestModel()
      m.resolve('a', null).reactNow((x) -> values.push(x))

      m.set('a', 2)
      values.should.eql([ null, 2 ])

    it 'should do nothing if no attribute is declared', ->
      value = -1
      m = new Model()
      m.resolve('a', null).reactNow((x) -> value = x)
      should(value).equal(null)

    it 'should return the proper value for a resolved reference attribute', ->
      values = []

      class TestModel extends Model
        @attribute('a', attribute.ReferenceAttribute)

      m = new TestModel()
      m.set('a', 1)

      m.resolve('a', null).reactNow((x) -> values.push(x))
      m.set('a', 2)
      values.should.eql([ 1, 2 ])

    it 'should point the reference request from the store library given an app', ->
      ourRequest = new Varying()
      givenRequest = null
      app = { getStore: ((x) -> givenRequest = x; { handle: (->), destroy: (->) }) }
      class TestModel extends Model
        @attribute 'a', class extends attribute.ReferenceAttribute
          request: -> ourRequest

      m = new TestModel()
      v = m.resolve('a', app)
      should(givenRequest).equal(null) # doesn't actually point until reacted.
      v.reactNow(->)
      givenRequest.should.equal(ourRequest)

    it 'calls handle on the store that handles the request', ->
      called = false
      app = { getStore: (x) -> { handle: (-> called = true), destroy: (->) } }
      class TestModel extends Model
        @attribute 'a', class extends attribute.ReferenceAttribute
          request: -> new Varying()

      m = new TestModel()
      v = m.resolve('a', app)
      called.should.equal(false) # doesn't actually point until reacted.
      v.reactNow(->)
      called.should.equal(true)

    it 'fails gracefully if no store is found to handle the request', ->
      app = { vendStore: -> null }
      class TestModel extends Model
        @attribute 'a', class extends attribute.ReferenceAttribute
          request: -> new Varying()

      m = new TestModel()
      v = m.resolve('a', app)
      v.reactNow(->)
      should(v.get()).equal(undefined)

    it 'destroys the store if the refcount drops to zero', ->
      destroyed = 0
      app = { getStore: -> { handle: (->), destroy: (-> destroyed++) } }
      class TestModel extends Model
        @attribute 'a', class extends attribute.ReferenceAttribute
          request: -> new Varying()

      m = new TestModel()
      v = m.resolve('a', app)
      vda = v.reactNow(->)
      vdb = v.reactNow(->)
      destroyed.should.equal(0)
      vda.stop()
      vdb.stop()
      destroyed.should.equal(1)

    it 'immediately calls handle on the store that handles the request given resolveNow', ->
      called = false
      app = { getStore: (x) -> { handle: (-> called = true), destroy: (->) } }
      class TestModel extends Model
        @attribute 'a', class extends attribute.ReferenceAttribute
          request: -> new Varying()

      m = new TestModel()
      m.resolveNow('a', app)
      called.should.equal(true)

    it 'relinquishes its hold on the resolveNow`d request if it reaches completion', ->
      called = false
      request = null
      app = { getStore: (x) -> { handle: (-> request = x), destroy: (-> called = true) } }
      class TestModel extends Model
        @attribute 'a', class extends attribute.ReferenceAttribute
          request: -> new Varying()

      m = new TestModel()
      m.resolveNow('a', app)
      request.set(types.result.failure(47))
      called.should.equal(true)

    it 'gives the request\'s inner value as its own', ->
      value = null
      request = new Varying()
      app = { getStore: (x) -> { handle: (->), destroy: (->) } }
      class TestModel extends Model
        @attribute 'a', class extends attribute.ReferenceAttribute
          request: -> request

      m = new TestModel()
      m.resolve('a', app).reactNow((x) -> value = x)
      should(value).equal(undefined)

      request.set(types.result.progress(26))
      value.should.equal('progress')
      value.value.should.equal(26)

      request.set(types.result.success())
      value.should.equal('success')
      value.value.should.be.an.instanceof(Model)

    it 'deserializes with the attribute\'s declared contained class deserializer', ->
      called = false
      value = null
      request = new Varying()
      app = { getStore: (x) -> { handle: (->), destroy: (->) } }
      class TestInner extends Model
        @deserialize: (data) ->
          called = true
          super(data)
      class TestModel extends Model
        @attribute 'a', class extends attribute.ReferenceAttribute
          @contains: TestInner
          request: -> request

      m = new TestModel()
      m.resolve('a', app).reactNow((x) -> value = x)

      request.set(types.result.success({ a: 42 }))
      called.should.equal(true)
      value.should.equal('success')
      value.value.get('a').should.equal(42)

    it 'resolves correctly when given a value in handle()', ->
      value = null
      app = { getStore: (x) -> { handle: (-> x.set(types.result.success({ a: 42 }))), destroy: (->) } }
      class TestModel extends Model
        @attribute 'a', class extends attribute.ReferenceAttribute
          request: -> new Varying()

      m = new TestModel()
      m.resolve('a', app).reactNow((x) -> value = x)
      value.should.equal('success')
      value.value.get('a').should.equal(42)

    it 'sets a successful value concretely if found', ->
      value = null
      request = new Varying()
      app = { getStore: (x) -> { handle: (->), destroy: (->) } }
      class TestModel extends Model
        @attribute 'a', class extends attribute.ReferenceAttribute
          request: -> request

      m = new TestModel()
      m.resolve('a', app).reactNow(->)
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
      issueList = new List()

      class TestModel extends Model
        _issues: -> issueList

      model = new TestModel()
      model.issues().list.length.should.equal(0)

      issueList.add(new Issue( active: true ))
      model.issues().list.length.should.equal(1)

      issueList.removeAll()
      model.issues().list.length.should.equal(0)

    it 'should contain issues from the Attribute level', ->
      issueList = new List()

      class TestModel extends Model
        @attribute 'attr', class extends attribute.Attribute
          issues: -> issueList

      model = new TestModel()
      model.issues().list.length.should.equal(0)

      issueList.add(new Issue( active: true ))
      model.issues().list.length.should.equal(1)

      issueList.removeAll()
      model.issues().list.length.should.equal(0)

    it 'should only contain active issues', ->
      class TestModel extends Model
        @attribute 'attr', class extends attribute.Attribute
          issues: -> new List([ new Issue( active: this.watchValue() ) ])

      model = new TestModel( attr: false )
      model.issues().list.length.should.equal(0)

      model.set('attr', true)
      model.issues().list.length.should.equal(1)

      model.set('attr', false)
      model.issues().list.length.should.equal(0)

  describe 'validity', ->
    it 'should return true if no active issues exist', ->
      class TestModel extends Model
        @attribute 'attr', class extends attribute.Attribute
          issues: -> new List([ new Issue( active: this.watchValue() ) ])

      model = new TestModel( attr: false )
      model.valid().get().should.equal(true)

    it 'should return false if one or more active issues exist', ->
      class TestModel extends Model
        @attribute 'attr', class extends attribute.Attribute
          issues: -> new List([ new Issue( active: this.watchValue() ) ])

        @attribute 'attr2', class extends attribute.Attribute
          issues: -> new List([ new Issue( active: this.watchValue() ) ])

      model = new TestModel( attr: true, attr2: false )
      model.valid().get().should.equal(false)

      model.set('attr2', true)
      model.valid().get().should.equal(false)

      model.set('attr', false)
      model.set('attr2', false)
      model.valid().get().should.equal(true)

    it 'should take a severity threshold', ->
      class TestModel extends Model
        @attribute 'attr', class extends attribute.Attribute
          issues: ->
            new List([
              new Issue( active: this.watchValue().map((val) -> val > 0), severity: 2 )
              new Issue( active: this.watchValue().map((val) -> val > 1), severity: 1 )
            ])

      model = new TestModel( attr: 0 )
      model.valid().get().should.equal(true)

      model.set('attr', 1)
      model.valid(1).get().should.equal(true)
      model.valid(2).get().should.equal(false)

      model.set('attr', 2)
      model.valid(1).get().should.equal(false)
      model.valid(2).get().should.equal(false)

  describe 'deserialization', ->
    it 'should store the given data into the correct places', ->
      Model.deserialize( a: { b: 1, c: 2 }, d: 3 ).attributes.should.eql({ a: { b: 1, c: 2 }, d: 3 })

    it 'should rely on provided attributes to deserialize if given', ->
      class TestModel extends Model
        @attribute 'a', class extends attribute.Attribute
          @deserialize: (x) -> "a#{x}"

        @attribute 'b.c', class extends attribute.Attribute
          @deserialize: (x) -> "bc#{x}"

        @attribute('b.d', attribute.Attribute)

        @attribute 'x', class extends attribute.Attribute
          @deserialize: (x) -> "x#{x}"

      TestModel.deserialize( a: 1, b: { c: 2, d: 3 } ).attributes.should.eql({ a: 'a1', b: { c: 'bc2', d: 3 } })

