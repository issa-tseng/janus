should = require('should')

from = require('../../lib/core/from')
types = require('../../lib/util/types')

Model = require('../../lib/model/model').Model
Issue = require('../../lib/model/issue').Issue
attribute = require('../../lib/model/attribute')

Varying = require('../../lib/core/varying').Varying
collection = require('../../lib/collection/collection')

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

  describe 'attribute', ->
    describe 'get', ->
      it 'should be able to get a shallow attribute', ->
        model = new Model( vivace: 'brix' )
        model.get('vivace').should.equal('brix')

      it 'should be able to get a deep attribute', ->
        model = new Model( cafe: { vivace: 'brix' } )
        model.get('cafe.vivace').should.equal('brix')

      it 'should return null on nonexistent attributes', ->
        model = new Model( broad: 'way' )
        (model.get('vivace') is null).should.be.true
        (model.get('cafe.vivace') is null).should.be.true

    describe 'set', ->
      it 'should be able to set a shallow attribute', ->
        model = new Model()
        model.set('colman', 'pool')

        model.attributes.colman.should.equal('pool')
        model.get('colman').should.equal('pool')

      it 'should be able to set a deep attribute', ->
        model = new Model()
        model.set('colman.pool', 'slide')

        model.attributes.colman.pool.should.equal('slide')
        model.get('colman.pool').should.equal('slide')

      it 'should be able to set a deep attribute bag', ->
        model = new Model()
        model.set('colman.pool', { location: 'west seattle', length: { amount: 50, unit: 'meter' } })

        model.get('colman.pool.location').should.equal('west seattle')
        model.get('colman.pool.length.amount').should.equal(50)
        model.get('colman.pool.length.unit').should.equal('meter')

      it 'should accept a bag of attributes', ->
        model = new Model()
        model.set( the: 'stranger' )

        model.attributes.the.should.equal('stranger')

      it 'should deep write all attributes in a given bag', ->
        model = new Model( the: { stranger: 'seattle' } )
        model.set( the: { joule: 'apartments' }, black: 'dog' )

        model.attributes.the.stranger.should.equal('seattle')
        model.get('the.stranger').should.equal('seattle')

        model.attributes.the.joule.should.equal('apartments')
        model.get('the.joule').should.equal('apartments')

        model.attributes.black.should.equal('dog')
        model.get('black').should.equal('dog')

    describe 'unset', ->
      it 'should be able to unset an attribute', ->
        model = new Model( cafe: { vivace: 'brix' } )
        model.unset('cafe.vivace')

        (model.get('cafe.vivace') is null).should.be.true

      it 'should be able to unset an attribute tree', ->
        model = new Model( cafe: { vivace: 'brix' } )
        model.unset('cafe')

        (model.get('cafe.vivace') is null).should.be.true
        (model.get('cafe') is null).should.be.true

    describe 'setAll', ->
      it 'should set all attributes in the given bag', ->
        model = new Model()
        model.setAll( the: { stranger: 'seattle', joule: 'apartments' } )

        model.attributes.the.stranger.should.equal('seattle')
        model.get('the.stranger').should.equal('seattle')

        model.attributes.the.joule.should.equal('apartments')
        model.get('the.joule').should.equal('apartments')

      it 'should clear attributes not in the given bag', ->
        model = new Model( una: 'bella', tazza: { di: 'caffe' } )
        model.setAll( tazza: { of: 'cafe' } )

        should.not.exist(model.attributes.una)
        (model.get('una') is null).should.be.true
        should.not.exist(model.attributes.tazza.di)
        (model.get('tazza.di') is null).should.be.true

        model.attributes.tazza.of.should.equal('cafe')
        model.get('tazza.of').should.equal('cafe')

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

  describe 'resolving', ->
    it 'should behave like watch for non-reference attributes', ->
      values = []

      class TestModel extends Model
        @attribute('a', attribute.NumberAttribute)

      m = new TestModel()
      m.resolve('a', null).reactNow((x) -> values.push(x))

      m.set('a', 2)
      values.should.eql([ null, 2 ])

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
      app = { getStore: ((x) -> givenRequest = x; { handle: (->) }) }
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
      app = { getStore: (x) -> { handle: (-> called = true) } }
      class TestModel extends Model
        @attribute 'a', class extends attribute.ReferenceAttribute
          request: -> new Varying()

      m = new TestModel()
      v = m.resolve('a', app)
      called.should.equal(false) # doesn't actually point until reacted.
      v.reactNow(->)
      called.should.equal(true)

    it 'gives the request\'s inner value as its own', ->
      value = null
      request = new Varying()
      app = { getStore: (x) -> { handle: (->) } }
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
      value.should.be.an.instanceof(Model)

    it 'deserializes with the attribute\'s declared contained class deserializer', ->
      called = false
      value = null
      request = new Varying()
      app = { getStore: (x) -> { handle: (->) } }
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
      value.get('a').should.equal(42)

    it 'resolves correctly when given a value in handle()', ->
      value = null
      app = { getStore: (x) -> { handle: -> x.set(types.result.success({ a: 42 })) } }
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
      app = { getStore: (x) -> { handle: (->) } }
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
      issues.should.be.an.instanceof(collection.Collection)
      issues.list.length.should.equal(0)

    it 'should contain issues from the Model level', ->
      issueList = new collection.List()

      class TestModel extends Model
        _issues: -> issueList

      model = new TestModel()
      model.issues().list.length.should.equal(0)

      issueList.add(new Issue( active: true ))
      model.issues().list.length.should.equal(1)

      issueList.removeAll()
      model.issues().list.length.should.equal(0)

    it 'should contain issues from the Attribute level', ->
      issueList = new collection.List()

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
          issues: -> new collection.List([ new Issue( active: this.watchValue() ) ])

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
          issues: -> new collection.List([ new Issue( active: this.watchValue() ) ])

      model = new TestModel( attr: false )
      model.valid().get().should.equal(true)

    it 'should return false if one or more active issues exist', ->
      class TestModel extends Model
        @attribute 'attr', class extends attribute.Attribute
          issues: -> new collection.List([ new Issue( active: this.watchValue() ) ])

        @attribute 'attr2', class extends attribute.Attribute
          issues: -> new collection.List([ new Issue( active: this.watchValue() ) ])

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
            new collection.List([
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

  describe 'shadowing', ->
    describe 'creation', ->
      it 'should create a new instance of the same model class', ->
        class TestModel extends Model

        model = new TestModel()
        shadow = model.shadow()

        shadow.should.not.equal(model)
        shadow.should.be.an.instanceof(TestModel)

      it 'should return the original of a shadow', ->
        model = new Model()
        model.shadow().original().should.equal(model)

      it 'should return the original of a shadow\'s shadow', ->
        model = new Model()
        model.shadow().shadow().original().should.equal(model)

      it 'should return all shadow parents of a model', ->
        a = new Model()
        b = a.shadow()
        c = b.shadow()

        originals = c.originals()
        originals.length.should.equal(2)
        originals[0].should.equal(b)
        originals[1].should.equal(a)

      it 'should return an empty array if it is an original asked for parents', ->
        (new Model()).originals().should.eql([])

      it 'should return itself as the original if it is not a shadow', ->
        model = new Model()
        model.original().should.equal(model)

    describe 'attributes', ->
      it 'should return the parent\'s values', ->
        model = new Model( test1: 'a' )
        shadow = model.shadow()

        shadow.get('test1').should.equal('a')

        model.set('test2', 'b')
        shadow.get('test2').should.equal('b')

      it 'should override the parent\'s values with its own', ->
        model = new Model( test: 'x' )
        shadow = model.shadow()

        shadow.get('test').should.equal('x')
        shadow.set('test', 'y')
        shadow.get('test').should.equal('y')

        model.get('test').should.equal('x')

      it 'should revert to the parent\'s value on revert()', ->
        model = new Model( test: 'x' )
        shadow = model.shadow()

        shadow.set('test', 'y')
        shadow.get('test').should.equal('y')

        shadow.revert('test')
        shadow.get('test').should.equal('x')

      it 'should do nothing on revert() if there is no parent', ->
        model = new Model( test: 'x' )
        model.revert('test')
        model.get('test').should.equal('x')

      it 'should return null for values that have been set and unset, even if the parent has values', ->
        model = new Model( test: 'x' )
        shadow = model.shadow()

        shadow.set('test', 'y')
        shadow.get('test').should.equal('y')

        shadow.unset('test')
        (shadow.get('test') is null).should.equal(true)

        shadow.revert('test')
        shadow.get('test').should.equal('x')

      it 'should return null for values that have been directly unset, even if the parent has values', ->
        model = new Model( test: 'x' )
        shadow = model.shadow()

        shadow.unset('test')
        (shadow.get('test') is null).should.equal(true)

      it 'should return a shadow submodel if it sees a model', ->
        submodel = new Model()
        model = new Model( test: submodel )

        shadow = model.shadow()
        shadow.get('test').original().should.equal(submodel)

    describe 'events', ->
      it 'should event when an inherited attribute value changes', ->
        model = new Model( test: 'x' )
        shadow = model.shadow()

        evented = false
        shadow.watch('test').react (value) ->
          evented = true
          value.should.equal('y')

        model.set('test', 'y')
        evented.should.equal(true)

      it 'should not event when an overriden inherited attribute changes', ->
        model = new Model( test: 'x' )
        shadow = model.shadow()

        shadow.set('test', 'y')

        evented = false
        shadow.watch('test').react(-> evented = true)

        model.set('test', 'z')
        evented.should.equal(false)

    describe 'merging', ->
      it 'should merge overriden changes up to its parent on merge()', ->
        model = new Model( test: 'x' )
        shadow = model.shadow()

        shadow.set('test', 'y')
        shadow.merge()

        model.get('test').should.equal('y')

      it 'should merge new attributes up to its parent on merge()', ->
        model = new Model()
        shadow = model.shadow()

        shadow.set('test', 'x')
        shadow.merge()

        model.get('test').should.equal('x')

      it 'should clear unset attributes up to its parent on merge()', ->
        model = new Model( test: 'x' )
        shadow = model.shadow()

        shadow.unset('test')
        shadow.merge()

        should.not.exist(model.get('test'))

    describe 'modification detection', ->
      it 'should return false if a model has no parent', ->
        model = new Model()
        model.modified().should.equal(false)
        model.attrModified('test').should.equal(false)

      describe 'attribute', ->
        it 'should return whether an attribute has changed', ->
          model = new Model( test: 'x', test2: 'y' )
          shadow = model.shadow()

          shadow.set('test', 'z')
          shadow.attrModified('test').should.equal(true)
          shadow.attrModified('test2').should.equal(false)

        it 'should handle unset values correctly', ->
          model = new Model( test: 'x' )
          shadow = model.shadow()

          shadow.unset('test')
          shadow.attrModified('test').should.equal(true)

          shadow.unset('test2')
          shadow.attrModified('test2').should.equal(false)

        it 'should handle newly set attributes correctly', ->
          model = new Model()
          shadow = model.shadow()

          shadow.set('test', new Model())
          shadow.attrModified('test').should.equal(true)

        it 'should ignore transient attributes', ->
          class TestModel extends Model
            @attribute 'test', class extends attribute.Attribute
              transient: true

          model = new TestModel( test: 'x' )
          shadow = model.shadow()

          shadow.set('test', 'y')
          shadow.attrModified('test').should.equal(false)

        it 'should compare model modified on deep compare', ->
          model = new Model( test: new Model() )
          shadow = model.shadow()

          shadow.get('test').set('test2', 'x')
          shadow.attrModified('test', true).should.equal(true)

        it 'should call a function to determine deepness with the right params', ->
          model = new Model( test: new Model() )
          shadow = model.shadow()

          nested = new Model()
          shadow.set('test', nested)

          called = false
          isDeep = (obj, path, val) ->
            obj.should.equal(shadow)
            path.should.equal('test')
            val.should.equal(nested)
            called = true

          shadow.attrModified('test', isDeep)
          called.should.equal(true)

        it 'should use the result of the function to determine deepness', ->
          model = new Model( test: new Model() )
          shadow = model.shadow()

          shadow.get('test').set('x', 'y')

          shadow.attrModified('test', -> true).should.equal(true)
          shadow.attrModified('test', -> false).should.equal(false)

        it 'should pass the function through if deep', ->
          model = new Model( test: new Model( test2: 'x' ) )
          shadow = model.shadow()

          shadow.get('test').set('test2', 'y')

          called = 0
          isDeep = -> called += 1; true
          shadow.attrModified('test', isDeep)

          called.should.equal(2)

      describe 'model', ->
        it 'should return whether any attributes have changed', ->
          model = new Model( test: 'x' )
          shadow = model.shadow()

          shadow.modified().should.equal(false)

          shadow.set('test2', 'y')
          shadow.modified().should.equal(true)

      describe 'watch shallow', ->
        it 'should vary depending on the modified state', ->
          model = new Model()
          shadow = model.shadow()

          expected = [ false, true, false ]
          shadow.watchModified(false).reactNow((isModified) -> isModified.should.equal(expected.shift()))

          shadow.set('test', 'x')
          shadow.unset('test')

          expected.length.should.equal(0)

        it 'should watch nested models shallowly', ->
          model = new Model( test: new Model() )
          shadow = model.shadow()

          evented = false
          shadow.watchModified(false).reactNow((value) -> evented = true if value is true)

          shadow.get('test').set('test2', 'x')
          evented.should.equal(false)

        it 'should watch shallowly if a falsy function is provided', ->
          model = new Model( test: new Model() )
          shadow = model.shadow()

          evented = false
          shadow.watchModified(-> false).reactNow((value) -> evented = true if value is true)

          shadow.get('test').set('test2', 'x')
          evented.should.equal(false)

      describe 'watch deep', ->
        it 'should vary depending on own modified state', ->
          model = new Model()
          shadow = model.shadow()

          expected = [ false, true, false ]
          shadow.watchModified().reactNow((isModified) -> isModified.should.equal(expected.shift()))

          shadow.set('test', 'x')
          shadow.unset('test')

          expected.length.should.equal(0)

        it 'should vary depending on submodel state', ->
          model = new Model( test: new Model() )
          shadow = model.shadow()

          expected = [ false, true, false ]
          shadow.watchModified().reactNow((isModified) -> isModified.should.equal(expected.shift()))

          shadow.get('test').set('test2', 'x')
          shadow.get('test').revert('test2')

        it 'should vary depending on new submodel state', ->
          model = new Model()
          shadow = model.shadow()

          evented = false
          shadow.watchModified().reactNow((isModified) -> evented = true if isModified)

          model.set('test', new Model())
          evented.should.equal(false)

          shadow.get('test').set('test2', 'x')
          evented.should.equal(true)

        it 'should not vary depending on discarded submodel state', ->
          model = new Model( test: new Model() )
          shadow = model.shadow()

          expected = [ false, true, false ]
          shadow.watchModified().reactNow((isModified) -> isModified.should.equal(expected.shift()))

          submodel = shadow.get('test')
          submodel.set('test2', 'x')
          shadow.unset('test')

          submodel.set('test3', 'y')

        it 'should watch deeply if a truish function is provided', ->
          model = new Model( test: new Model() )
          shadow = model.shadow()

          evented = false
          shadow.watchModified(-> true).reactNow((value) -> evented = true if value is true)

          shadow.get('test').set('test2', 'x')
          evented.should.equal(true)

        it 'should pass through the deepness function', ->
          nested = new Model( test2: new Model() )
          model = new Model( test: nested )
          shadow = model.shadow()

          evented = false
          shadow.watchModified((model) -> model.original() isnt nested).reactNow((value) -> evented = true if value is true)

          shadow.get('test').get('test2').set('x', 'y')
          evented.should.equal(false)

          shadow.get('test').set('a', 'b')
          evented.should.equal(true)

