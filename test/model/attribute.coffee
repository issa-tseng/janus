should = require('should')

{ Varying } = require('../../lib/core/varying')
from = require('../../lib/core/from')
types = require('../../lib/core/types')
{ Model } = require('../../lib/model/model')
attribute = require('../../lib/model/attribute')

{ List } = require('../../lib/collection/list')

describe 'Attribute', ->
  describe 'value manipulation', ->
    it 'can set a value onto the model', ->
      m = new Model()
      a = new attribute.Attribute(m, 'testkey')

      should(m.get_('testkey')).equal(null)
      a.setValue(42)
      m.get_('testkey').should.equal(42)

    it 'can unset a value off the model', ->
      m = new Model({ testkey: 42 })
      a = new attribute.Attribute(m, 'testkey')

      m.get_('testkey').should.equal(42)
      a.unsetValue()
      should(m.get_('testkey')).equal(null)

    it 'can get a value off the model', ->
      m = new Model({ testkey: 42 })
      a = new attribute.Attribute(m, 'testkey')

      a.getValue_().should.equal(42)
      m.set('testkey', 47)
      a.getValue_().should.equal(47)

    it 'can watch a value off the model', ->
      m = new Model({ testkey: 42 })
      a = new attribute.Attribute(m, 'testkey')

      results = []
      a.getValue().react((x) -> results.push(x))
      m.set('testkey', 47)
      m.set('testkey', 101)
      results.should.eql([ 42, 47, 101 ])

  describe 'default values', ->
    it 'will give the default value if no value exists', ->
      m = new Model()
      class TestAttribute extends attribute.Attribute
        default: -> 42

      a = new TestAttribute(m, 'default_test')
      a.getValue_().should.equal(42)
      # Model#get respecting the default value is tested in model tests.

    # note these are distinct from the model tests; different codepath.
    it 'does not write the default value by default', ->
      m = new Model()
      class TestAttribute extends attribute.Attribute
        default: -> 42

      a = new TestAttribute(m, 'default_test')
      a.getValue_().should.equal(42)
      m.data.should.eql({})

    it 'writes the default value if writeDefault is true', ->
      m = new Model()
      class TestAttribute extends attribute.Attribute
        default: -> 42
        writeDefault: true

      a = new TestAttribute(m, 'default_test')
      m.data.should.eql({})
      a.getValue_().should.equal(42)
      m.data.should.eql({ default_test: 42 })

  describe 'serialization', ->
    it 'just returns the data by default on deserialization', ->
      data = {}
      attribute.Attribute.deserialize(data).should.equal(data)

    it 'just returns the value by default on serialization', ->
      m = new Model({ testkey: 42 })
      (new attribute.Attribute(m, 'testkey')).serialize().should.equal(42)

    it 'returns nothing if transient on serialization', ->
      class TestAttribute extends attribute.Attribute
        transient: true

      m = new Model({ testkey: 42 })
      should((new TestAttribute(m, 'testkey')).serialize()).equal(undefined)

  describe 'standard', ->
    describe 'date type', ->
      it 'should deserialize by feeding the value to Date by default', ->
        attribute.Date.deserialize(0).should.be.an.instanceof(Date)

      it 'should serialize by chomping Date down to epoch millis', ->
        m = new Model({ date: new Date() })
        result = (new attribute.Date(m, 'date')).serialize()
        result.should.be.a.Number
        (result > 1400000000000).should.equal(true)

    describe 'enum type', ->
      it 'should by default give an empty Varying[List]', ->
        attr = new attribute.Enum(new Model(), 'test')
        values = attr.values()
        values.isVarying.should.equal(true)
        values.get().should.be.an.instanceof(List)
        values.get().length_.should.equal(0)

      it 'should give the specified array if declared', ->
        class TestAttribute extends attribute.Enum
          _values: -> [ 'red', 'blue', 'green' ]

        attr = new TestAttribute(new Model(), 'test')
        values = attr.values()
        values.get().should.be.an.instanceof(List)
        values.get().list.should.eql([ 'red', 'blue', 'green' ])

      it 'should give the specified list if declared', ->
        class TestAttribute extends attribute.Enum
          _values: -> new List([ 'red', 'blue', 'green' ])

        attr = new TestAttribute(new Model(), 'test')
        values = attr.values()
        values.get().should.be.an.instanceof(List)
        values.get().list.should.eql([ 'red', 'blue', 'green' ])

      it 'should resolve a from binding if given', ->
        class TestAttribute extends attribute.Enum
          _values: -> from('list')

        m = new Model({ list: new List([ 'red', 'blue', 'green' ]) })
        attr = new TestAttribute(m, 'test')
        values = attr.values()
        values.get().should.be.an.instanceof(List)
        values.get().list.should.eql([ 'red', 'blue', 'green' ])

    describe 'model type', ->
      it 'should delegate deserialization to the model class', ->
        called = false
        class TestModel extends Model
          @deserialize: -> called = true; 42
        class TestAttribute extends attribute.Model
          @modelClass: TestModel

        TestAttribute.deserialize({}).should.equal(42)
        called.should.equal(true)

      it 'should delegate serialization to the model class', ->
        called = false
        class TestModel extends Model
          serialize: -> called = true; 42
        class TestAttribute extends attribute.Model
          @modelClass: TestModel

        (new TestAttribute(new Model(), 'whatever')).serialize().should.equal(42)
        called.should.equal(true)

      it 'should not serialize if transient', ->
        class TestAttribute extends attribute.Model
          @modelClass: Model
          transient: true

        should((new TestAttribute(new Model(), 'whatever')).serialize()).equal(undefined)

      it 'should allow Model.of(x) shortcut definition', ->
        class MyModel extends Model
        MyAttribute = attribute.Model.of(MyModel)
        MyAttribute.modelClass.should.equal(MyModel)

      it 'should allow Model.withDefault() shortcut definition', ->
        a = new (attribute.Model.withDefault())(new Model(), 'test')
        m = a.getValue_()
        m.should.be.an.instanceof(Model)
        a.getValue_().should.equal(m)

      it 'should combine of and withDefault shortcuts correctly', ->
        class TestModel extends Model
        a = new (attribute.Model.of(TestModel).withDefault())(new Model(), 'test')
        a.getValue_().should.be.an.instanceof(TestModel)

    describe 'list type', ->
      it 'should delegate deserialization to the list class', ->
        called = false
        class TestList extends List
          @deserialize: -> called = true; 42
        class TestAttribute extends attribute.List
          @listClass: TestList

        TestAttribute.deserialize({}).should.equal(42)
        called.should.equal(true)

      it 'should delegate serialization to the list class', ->
        called = false
        class TestList extends List
          serialize: -> called = true; 42
        class TestAttribute extends attribute.List
          @listClass: TestList

        (new TestAttribute(new Model(), 'whatever')).serialize().should.equal(42)
        called.should.equal(true)

      it 'should not serialize if transient', ->
        class TestAttribute extends attribute.List
          @listClass: List
          transient: true

        should((new TestAttribute(new Model(), 'whatever')).serialize()).equal(undefined)

      it 'should allow List.of(x) shortcut definition', ->
        class MyList extends List
        MyAttribute = attribute.List.of(MyList)
        MyAttribute.listClass.should.equal(MyList)

      it 'should allow List.withDefault() shortcut definition', ->
        a = new (attribute.List.withDefault())(new Model(), 'test')
        l = a.getValue_()
        l.should.be.an.instanceof(List)
        a.getValue_().should.equal(l)

      it 'should combine of and withDefault shortcuts correctly', ->
        class TestList extends List
        a = new (attribute.List.of(TestList).withDefault())(new Model(), 'test')
        a.getValue_().should.be.an.instanceof(TestList)

    describe 'reference type', ->
      it 'should only try to resolve once', ->
        called = 0
        class TestModel
          get: -> called += 1; new Varying()
        ref = new (attribute.Reference.to(6.626))(new TestModel())
        ref.resolveWith()
        ref.resolveWith()
        called.should.equal(1)

      it 'should not try to do anything until the key is observed', ->
        key = null
        called = false
        reacted = false
        v = new Varying()
        class TestModel
          get: (k) -> key = k; v

        ref = new (attribute.Reference.to({ isRequest: true }))(new TestModel(), 1.055)
        ref.resolveWith({ resolve: -> called = true; { react: -> reacted = true } })

        key.should.equal(1.055)
        called.should.equal(false)
        reacted.should.equal(false)

        v.react(->)
        called.should.equal(true)
        reacted.should.equal(true)

      it 'should directly resolve bare requests', ->
        calledWith = null
        v = new Varying()
        class TestModel
          get: -> v

        ref = new (attribute.Reference.to({ isRequest: true, test: 4.136 }))(new TestModel())
        ref.resolveWith({ resolve: (req) -> calledWith = req; new Varying() })
        v.react(->)
        calledWith.test.should.equal(4.136)

      it 'should call request if it is a function', ->
        calledWith = null
        v = new Varying()
        class TestModel
          get: -> v

        class TestReference extends attribute.Reference
          request: -> { isRequest: true, test: 4.136 }

        ref = new TestReference(new TestModel())
        ref.resolveWith({ resolve: (req) -> calledWith = req; new Varying() })
        v.react(->)
        calledWith.test.should.equal(4.136)

      it 'should resolve Varyings containing requests', ->
        calledWith = null
        v = new Varying()
        class TestModel extends Model
          get: -> v

        ref = new (attribute.Reference.to(new Varying(6.582)))(new TestModel())
        ref.resolveWith({ resolve: (req) -> calledWith = req; new Varying() })
        v.react(->)
        calledWith.should.equal(6.582)

      it 'should point fromchains containing requests, then resolve', ->
        calledWith = null
        v = new Varying()
        class TestModel extends Model
          get: -> v

        ref = new (attribute.Reference.to(from.varying(new Varying(6.582))))(new TestModel())
        ref.resolveWith({ resolve: (req) -> calledWith = req; new Varying() })
        v.react(->)
        calledWith.should.equal(6.582)

      it 'should set the model value given successful results', ->
        vattr = new Varying()
        vreq = new Varying()
        class TestModel extends Model
          get: -> vattr

        m = new TestModel()
        ref = new (attribute.Reference.to({ isRequest: true }))(m, 'test')
        ref.resolveWith({ resolve: -> vreq })
        vattr.react(->)

        vreq.set(types.result.success(3.14))
        m.get_('test').should.equal(3.14)
        vreq.set(types.result.success(2.718))
        m.get_('test').should.equal(2.718)

      it 'should not set the model value given unsuccessful results', ->
        vattr = new Varying()
        vreq = new Varying()
        class TestModel extends Model
          get: -> vattr

        m = new TestModel()
        ref = new (attribute.Reference.to({ isRequest: true }))(m, 'test')
        ref.resolveWith({ resolve: -> vreq })
        vattr.react(->)

        vreq.set(types.result.failure(12))
        should.not.exist(m.get_('test'))
        vreq.set(types.result.success(24))
        m.get_('test').should.equal(24)

      it 'should stop caring about the request result if nobody is watching', ->
        vattr = new Varying()
        vreq = new Varying()
        class TestModel extends Model
          get: -> vattr

        m = new TestModel()
        ref = new (attribute.Reference.to({ isRequest: true }))(m, 'test')
        ref.resolveWith({ resolve: -> vreq })
        o = vattr.react(->)

        vreq.set(types.result.success(36))
        m.get_('test').should.equal(36)
        o.stop()
        vreq.set(types.result.success(48))
        m.get_('test').should.equal(36)

