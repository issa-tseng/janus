should = require('should')

{ Varying } = require('../../lib/core/varying')
from = require('../../lib/core/from')
types = require('../../lib/util/types')
{ Model } = require('../../lib/model/model')
attribute = require('../../lib/model/attribute')

{ List } = require('../../lib/collection/list')

describe 'Attribute', ->
  describe 'value manipulation', ->
    it 'can set a value onto the model', ->
      m = new Model()
      a = new attribute.Attribute(m, 'testkey')

      should(m.get('testkey')).equal(null)
      a.setValue(42)
      m.get('testkey').should.equal(42)

    it 'can unset a value off the model', ->
      m = new Model({ testkey: 42 })
      a = new attribute.Attribute(m, 'testkey')

      m.get('testkey').should.equal(42)
      a.unsetValue()
      should(m.get('testkey')).equal(null)

    it 'can get a value off the model', ->
      m = new Model({ testkey: 42 })
      a = new attribute.Attribute(m, 'testkey')

      a.getValue().should.equal(42)
      m.set('testkey', 47)
      a.getValue().should.equal(47)

    it 'can watch a value off the model', ->
      m = new Model({ testkey: 42 })
      a = new attribute.Attribute(m, 'testkey')

      results = []
      a.watchValue().react((x) -> results.push(x))
      m.set('testkey', 47)
      m.set('testkey', 101)
      results.should.eql([ 42, 47, 101 ])

  describe 'default values', ->
    it 'will give the default value if no value exists', ->
      m = new Model()
      class TestAttribute extends attribute.Attribute
        default: -> 42

      a = new TestAttribute(m, 'default_test')
      a.getValue().should.equal(42)
      # Model#get respecting the default value is tested in model tests.

    # note these are distinct from the model tests; different codepath.
    it 'does not write the default value by default', ->
      m = new Model()
      class TestAttribute extends attribute.Attribute
        default: -> 42

      a = new TestAttribute(m, 'default_test')
      a.getValue().should.equal(42)
      m.data.should.eql({})

    it 'writes the default value if writeDefault is true', ->
      m = new Model()
      class TestAttribute extends attribute.Attribute
        default: -> 42
        writeDefault: true

      a = new TestAttribute(m, 'default_test')
      m.data.should.eql({})
      a.getValue().should.equal(42)
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

    describe 'collection type', ->
      it 'should delegate deserialization to the collection class', ->
        called = false
        class TestCollection extends List
          @deserialize: -> called = true; 42
        class TestAttribute extends attribute.Collection
          @collectionClass: TestCollection

        TestAttribute.deserialize({}).should.equal(42)
        called.should.equal(true)

      it 'should delegate serialization to the collection class', ->
        called = false
        class TestCollection extends List
          serialize: -> called = true; 42
        class TestAttribute extends attribute.Collection
          @collectionClass: TestCollection

        (new TestAttribute(new Model(), 'whatever')).serialize().should.equal(42)
        called.should.equal(true)

      it 'should not serialize if transient', ->
        class TestAttribute extends attribute.Collection
          @collectionClass: List
          transient: true

        should((new TestAttribute(new Model(), 'whatever')).serialize()).equal(undefined)

      it 'should allow Collection.of(x) shortcut definition', ->
        class MyList extends List
        MyAttribute = attribute.Collection.of(MyList)
        MyAttribute.collectionClass.should.equal(MyList)

    describe 'reference type', ->
      it 'should only try to resolve once', ->
        called = 0
        class TestModel
          watch: -> called += 1; new Varying()
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
          watch: (k) -> key = k; v

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
          watch: -> v

        ref = new (attribute.Reference.to({ isRequest: true, test: 4.136 }))(new TestModel())
        ref.resolveWith({ resolve: (req) -> calledWith = req; new Varying() })
        v.react(->)
        calledWith.test.should.equal(4.136)

      it 'should point fromchains containing requests, then resolve', ->
        calledWith = null
        v = new Varying()
        class TestModel extends Model
          watch: -> v

        ref = new (attribute.Reference.to(from.varying(new Varying(6.582))))(new TestModel())
        ref.resolveWith({ resolve: (req) -> calledWith = req; new Varying() })
        v.react(->)
        calledWith.should.equal(6.582)

      it 'should set the model value given successful results', ->
        vattr = new Varying()
        vreq = new Varying()
        class TestModel extends Model
          watch: -> vattr

        m = new TestModel()
        ref = new (attribute.Reference.to({ isRequest: true }))(m, 'test')
        ref.resolveWith({ resolve: -> vreq })
        vattr.react(->)

        vreq.set(types.result.success(3.14))
        m.get('test').should.equal(3.14)
        vreq.set(types.result.success(2.718))
        m.get('test').should.equal(2.718)

      it 'should not set the model value given unsuccessful results', ->
        vattr = new Varying()
        vreq = new Varying()
        class TestModel extends Model
          watch: -> vattr

        m = new TestModel()
        ref = new (attribute.Reference.to({ isRequest: true }))(m, 'test')
        ref.resolveWith({ resolve: -> vreq })
        vattr.react(->)

        vreq.set(types.result.failure(12))
        should.not.exist(m.get('test'))
        vreq.set(types.result.success(24))
        m.get('test').should.equal(24)

      it 'should stop caring about the request result if nobody is watching', ->
        vattr = new Varying()
        vreq = new Varying()
        class TestModel extends Model
          watch: -> vattr

        m = new TestModel()
        ref = new (attribute.Reference.to({ isRequest: true }))(m, 'test')
        ref.resolveWith({ resolve: -> vreq })
        o = vattr.react(->)

        vreq.set(types.result.success(36))
        m.get('test').should.equal(36)
        o.stop()
        vreq.set(types.result.success(48))
        m.get('test').should.equal(36)

