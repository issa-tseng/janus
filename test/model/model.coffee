should = require('should')

from = require('../../lib/core/from')
types = require('../../lib/core/types')

Model = require('../../lib/model/model').Model
attributes = require('../../lib/model/attribute')
{ attribute, bind, dfault, validate, transient, Trait } = require('../../lib/model/schema')

Varying = require('../../lib/core/varying').Varying
{ List } = require('../../lib/collection/list')

describe 'Model', ->
  describe 'core', ->
    it 'should construct', ->
      (new Model()).should.be.an.instanceof(Model)

    it 'should construct with a data bag', ->
      (new Model( test: 'attr' )).data.test.should.equal('attr')

    it 'should call preinitialize before data is populated', ->
      result = -1
      class TestModel extends Model
        _preinitialize: -> result = this.get_('a')

      new TestModel({ a: 42 })
      should(result).equal(null)

    it 'should call initialize after data is populated', ->
      result = -1
      class TestModel extends Model
        _initialize: -> result = this.get_('a')

      new TestModel({ a: 42 })
      result.should.equal(42)

  describe 'get', ->
    it 'should return an appropriate Varying given a bound var', ->
      class TestModel extends Model.build(
        bind('y', from('x').map((x) -> x * 2))
      )
      model = new TestModel({ x: 4 })
      result = model.get('y')
      result.isVarying.should.equal(true)
      result.get().should.equal(8)

    it 'should return an appropriate Varying given a non-bound var', ->
      model = new Model({ x: 4 })
      result = model.get('x')
      result.isVarying.should.equal(true)
      result.get().should.equal(4)

    it 'should not crash if bound vars are get()ed before _bindings init', ->
      class TestModel extends Model.build(
        bind('y', from('x').map((x) -> x * 2)))
        _initialize: -> this.get('y').react(this.set('z'))
      m = new TestModel({ x: 4 })
      m.get_('z').should.equal(8) # really the test is that nothing crashes

  describe 'get_', ->
    it 'should return the default value if defined', ->
      class TestAttribute extends attributes.Attribute
        default: -> 'espresso'
      TestModel = Model.build(attribute('latte', TestAttribute))

      m = new TestModel()
      m.get_('latte').should.equal('espresso')

      m2 = new TestModel({ latte: 'good' })
      m2.get_('latte').should.equal('good')

    it 'should not write the default value if not specified', ->
      class TestAttribute extends attributes.Attribute
        default: -> 'espresso'
      TestModel = Model.build(attribute('latte', TestAttribute))

      m = new TestModel()
      m.get_('latte').should.equal('espresso')
      m.data.should.eql({})

    it 'should write the default value if writeDefault is true', ->
      class TestAttribute extends attributes.Attribute
        default: -> 'espresso'
        writeDefault: true
      TestModel = Model.build(attribute('latte', TestAttribute))

      m = new TestModel()
      m.data.should.eql({})
      m.get_('latte').should.equal('espresso')
      m.data.should.eql({ latte: 'espresso' })

    # before this bugfix, the result of .set() was always written, which meant
    # that if the default value was undefined, the .set(key) curried function
    # would get written into the model, which we do not want.
    it 'should not write a default value if writeDefault is true default is undefined', ->
      class TestAttribute extends attributes.Attribute
        writeDefault: true
      TestModel = Model.build(attribute('breve', TestAttribute))

      m = new TestModel()
      m.data.should.eql({})
      should.not.exist(m.get_('breve'))
      m.data.should.eql({})

    it 'should correctly ignore overshadowed unsets', ->
      m = new Model({ x: 2 })
      m2 = m.shadow()
      m2.unset('x')
      console.log(m2.get_('x'))
      (m2.get_('x') is null).should.equal(true)

    it 'should by default shadow parent-obtained enumerables', ->
      p = new Model({ a: 1 })
      m = new Model({ p })
      m2 = m.shadow()
      p2 = m2.get_('p')
      p2.set('a', 4)

      p2.get_('a').should.equal(4)
      p.get_('a').should.equal(1)

    it 'should now default shadow parent-obtained enumerables if the attribute flags shadow:false', ->
      TestModel = Model.build(
        attribute('p', class extends attributes.Attribute
          shadow: false
        )
      )

      p = new Model({ a: 1 })
      m = new TestModel({ p })
      m2 = m.shadow()
      m2.get_('p').should.equal(p)

  describe 'binding', ->
    describe 'application', ->
      it 'should bind one value from another', ->
        TestModel = Model.build(bind('dest', from('source')))
        model = new TestModel()
        should.not.exist(model.get_('dest'))

        model.set('source', 'aoeu')
        model.get_('dest').should.equal('aoeu')

      it 'should unset a value if its bound value nulls out', ->
        TestModel = Model.build(bind('inner_id', from('inner').get('id')))
        model = new TestModel( inner: new Model( id: 42 ) )
        console.log(model.get_('inner_id'))
        model.get_('inner_id').should.equal(42)

        model.unset('inner')
        console.log(model.get_('inner_id'))
        (model.get_('inner_id') is null).should.equal(true)

      it 'should map multiple value together', ->
        TestModel = Model.build(bind('c', from('a').and('b').all.map((a, b) -> a + b)))

        model = new TestModel()
        model.set( a: 3, b: 4 )

        model.get_('c').should.equal(7)

      it 'should be able to bind from a Varying', ->
        v = new Varying(2)
        TestModel = Model.build(bind('x', from.varying(-> v)))
        model = new TestModel()

        model.get_('x').should.equal(2)

        v.set(4)
        model.get_('x').should.equal(4)

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
        called.should.equal(true)

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
        m.get_('b').should.equal(1)

        v.set(2)
        m.get_('b').should.equal(2)

      it 'should point dynamic key names', ->
        TestModel = Model.build(bind('b', from('a')))

        m = new TestModel()
        m.set('a', 1)
        m.get_('b').should.equal(1)
        m.set('a', 2)
        m.get_('b').should.equal(2)

      it 'should point dynamic other objects', ->
        TestModel = Model.build(bind('b', from(42)))

        m = new TestModel()
        m.get_('b').should.equal(42)

      it 'should point get key names', ->
        TestModel = Model.build(bind('b', from.get('a')))

        m = new TestModel()
        m.set('a', 1)
        m.get_('b').should.equal(1)
        m.set('a', 2)
        m.get_('b').should.equal(2)

      it 'should point at subjects without a parameter', ->
        TestModel = Model.build(bind('x', from.subject()))
        m = new TestModel()
        should.not.exist(m.get_('x'))
        m.set('subject', 42)
        m.get_('x').should.equal(42)

      it 'should point at subject data given a parameter', ->
        TestModel = Model.build(bind('x', from.subject('y')))
        m = new TestModel()
        should.not.exist(m.get_('x'))
        m.set('subject', new Model({ y: 42 }))
        m.get_('x').should.equal(42)

      it 'should point attribute objects', ->
        TestModel = Model.build(
          attribute('a', attributes.Number)
          bind('b', from.attribute('a'))
        )

        m = new TestModel()
        m.get_('b').should.equal(m.attribute('a'))

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
        m.get_('b').should.equal(1)

        v.set(2)
        m.get_('b').should.equal(2)

      it 'should not point apps by default', ->
        TestModel = Model.build(bind('b', from.app()))

        m = new TestModel()
        m.get_('b').should.be.a.Function()

      it 'should point apps if given', ->
        app = {}
        m = new Model(null, { app })
        m.pointer()(types.from.app(), m, app).get().should.equal(app)

      it 'should point into app subkeys if given', ->
        watchedWith = null
        app = { get: (x) -> watchedWith = x; 'watched!' }
        m = new Model(null, { app })
        m.pointer()(types.from.app('test'), m, app).should.equal('watched!')
        watchedWith.should.equal('test')

      it 'should point self by function', ->
        calledWith = null
        TestModel = Model.build(bind('b', from.self((x) -> calledWith = x; 42)))

        m = new TestModel()
        calledWith.should.equal(m)
        m.get_('b').should.equal(42)

      it 'should point self statically', ->
        TestModel = Model.build(bind('b', from.self()))

        m = new TestModel()
        m.get_('b').should.equal(m)

    describe 'classtree', ->
      it 'should not pollute across classdefs', ->
        TestA = Model.build(bind('a', from('c')))
        TestB = Model.build(bind('b', from('c')))

        a = new TestA()

        b = new TestB()
        b.set('c', 47)
        should.not.exist(b.get_('a'))

      it 'should not pollute crosstree', ->
        Root = Model.build(bind('root', from('x')))
        Left = Model.build(bind('left', from('x')))
        Right = Model.build(bind('right', from('x')))

        root = new Root( x: 'root' )
        should.not.exist(root.get_('left'))
        should.not.exist(root.get_('right'))

        left = new Left( x: 'left' )
        should.not.exist(left.get_('right'))

        right = new Right( x: 'right' )
        should.not.exist(right.get_('left'))

      it 'should extend downtree', ->
        Root = Model.build(bind('root', from('x')))
        Child = Root.build(bind('child', from('x')))

        child = new Child( x: 'test' )
        child.get_('root').should.equal('test')
        child.get_('child').should.equal('test')

      it 'should allow child bind to override parent', ->
        Root = Model.build(bind('contend', from('x')))
        Child = Root.build(bind('contend', from('y')))

        (new Child( x: 1, y: 2 )).get_('contend').should.equal(2)

    describe 'shadowing', ->
      it 'should not propagate parent bound values', ->
        TestModel = Model.build(bind('b', from('a')))

        x = new TestModel( a: 2 )
        y = x.shadow()
        y.set('a', 3)
        x.set('a', 1)
        y.get_('b').should.equal(3)

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
      (new TestModel()).get_('test').should.equal(42)

    it 'should take a function with default for defining a default value', ->
      i = 0
      TestModel = Model.build(dfault('test', -> ++i))
      (new TestModel()).get_('test').should.equal(1)
      (new TestModel()).get_('test').should.equal(2)

    it 'should allow for the attribute class to be defined with @default', ->
      TestModel = Model.build(dfault('test', 42, attributes.Number))
      (new TestModel()).attribute('test').should.be.an.instanceof(attributes.Number)

    it 'should allow @transient shortcut to declare an attribute transient', ->
      TestModel = Model.build(transient('tempkey'))
      (new TestModel()).attribute('tempkey').transient.should.equal(true)

  describe 'autoresolution', ->
    it 'should call resolveWith on all known reference attributes', ->
      calls = []
      class TestReferenceAttribute extends attributes.Reference
        resolveWith: (app) -> calls.push([ this.key, app ])

      TestModel = Model.build(
        attribute('one', TestReferenceAttribute)
        attribute('two', attributes.Attribute)
        attribute('three', TestReferenceAttribute)
        attribute('four', attributes.Attribute)
      )
      (new TestModel()).autoResolveWith('app')
      calls.should.eql([ [ 'one', 'app' ], [ 'three', 'app' ] ])

    it 'should not resolve any attributes not marked for autoresolve', ->
      calls = []
      class TestReferenceAttribute extends attributes.Reference
        resolveWith: (app) -> calls.push([ this.key, app ])
        @flagged: (x) -> class extends this
          autoResolve: x

      TestModel = Model.build(
        attribute('one', TestReferenceAttribute.flagged(false))
        attribute('two', TestReferenceAttribute.flagged(true))
        attribute('three', TestReferenceAttribute.flagged(true))
        attribute('four', attributes.Attribute)
      )
      (new TestModel()).autoResolveWith('app')
      calls.should.eql([ [ 'two', 'app' ], [ 'three', 'app' ] ])

  describe 'validation', ->
    it 'should return all defined validations on validations()', ->
      v1 = new Varying(types.validity.valid())
      v2 = new Varying(types.validity.valid())
      TestModel = Model.build(
        validate(from(v1))
        validate(from(v2))
      )

      model = new TestModel()
      model.validations().length_.should.equal(2)
      types.validity.valid.match(model.validations().at_(0)).should.equal(true)
      types.validity.valid.match(model.validations().at_(1)).should.equal(true)

    it 'should return failing validations on errors()', ->
      v1 = new Varying(types.validity.valid())
      v2 = new Varying(types.validity.error('test'))
      TestModel = Model.build(
        validate(from(v1))
        validate(from(v2))
      )

      model = new TestModel()
      model.errors().length_.should.equal(1)
      model.errors().at_(0).should.equal('test')

    it 'should return true if no active errors exist on valid()', ->
      v1 = new Varying(types.validity.valid())
      v2 = new Varying(types.validity.valid())
      TestModel = Model.build(
        validate(from(v1))
        validate(from(v2))
      )

      model = new TestModel()
      model.valid().get().should.equal(true)

    it 'should return false if one or more active errors exist on valid()', ->
      v1 = new Varying(types.validity.error())
      v2 = new Varying(types.validity.error())
      TestModel = Model.build(
        validate(from(v1))
        validate(from(v2))
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
      m.get_('a').should.equal(2)
      m.get_('x').should.equal(4)

    it 'should work alongside direct definitions', ->
      TestTrait = Trait(
        bind('a', from('b'))
      )
      TestModel = Model.build(
        TestTrait
        bind('x', from('y'))
      )

      m = new TestModel( b: 2, y: 4 )
      m.get_('a').should.equal(2)
      m.get_('x').should.equal(4)

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
      m.get_('a').should.equal(2)
      m.get_('x').should.equal(4)

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

  describe 'lifecycle', ->
    it 'should destroy any created attributes when destroyed', ->
      destroyed = 0
      class TestAttribute extends attributes.Attribute
        destroy: ->
          destroyed += 1
          super()

      TestModel = Model.build(
        attribute('a', TestAttribute),
        attribute('b', TestAttribute),
        attribute('c', TestAttribute)
      )

      m = new TestModel()
      m.attribute('a')
      m.attribute('c')

      m.destroy()
      destroyed.should.equal(2)

    it 'should not attempt to destroy nonattributes', ->
      m = new Model()
      m.attribute('a')
      m.attribute('b')
      should.doesNotThrow(-> m.destroy())

