should = require('should')

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
          @bind('slave').from('master')

        model = new TestModel()
        should.not.exist(model.get('slave'))

        model.set('master', 'commander')
        model.get('slave').should.equal('commander')

      it 'should iterate into nodes', ->
        class TestModel extends Model
          @bind('child_id').from('child', 'id')

        (new TestModel( child: new Model( id: 1 ) )).get('child_id').should.equal(1)

      it 'should flatMap multiple attributes together', ->
        class TestModel extends Model
          @bind('c').from('a').and('b').flatMap((a, b) -> a + b)

        model = new TestModel()
        model.set( a: 3, b: 4 )

        model.get('c').should.equal(7)

      it 'should be able to bind from a Varying', ->
        v = new Varying(2)

        class TestModel extends Model
          @bind('x').fromVarying(-> v)

        model = new TestModel()

        model.get('x').should.equal(2)

        v.setValue(4)
        model.get('x').should.equal(4)

      it 'should give model as this in Varying bind', ->
        called = false
        class TestModel extends Model
          @bind('y').fromVarying ->
            called = true
            this.should.be.an.instanceof(TestModel)
            new Varying()

        new TestModel()
        called.should.be.true

      it 'should take a fallback', ->
        class TestModel extends Model
          @bind('z').from('a').fallback('value')

        model = new TestModel()

        model.get('z').should.equal('value')

        model.set('a', 'test')
        model.get('z').should.equal('test')

    describe 'classtree', ->
      it 'should not pollute across classdefs', ->
        class TestA extends Model
          @bind('a').from('c')

        class TestB extends Model
          @bind('b').from('c')

        a = new TestA()

        b = new TestB()
        b.set('c', 47)
        should.not.exist(b.get('a'))

      it 'should not pollute crosstree', ->
        class Root extends Model
          @bind('root').from('x')

        class Left extends Root
          @bind('left').from('x')

        class Right extends Root
          @bind('right').from('x')

        root = new Root( x: 'root' )
        should.not.exist(root.get('left'))
        should.not.exist(root.get('right'))

        left = new Left( x: 'left' )
        should.not.exist(left.get('right'))

        right = new Right( x: 'right' )
        should.not.exist(right.get('left'))

      it 'should extend downtree', ->
        class Root extends Model
          @bind('root').from('x')

        class Child extends Root
          @bind('child').from('x')

        (new Child( x: 'test' )).get('root').should.equal('test')

      it 'should allow child bind to override parent', ->
        class Root extends Model
          @bind('contend').from('x')

        class Child extends Root
          @bind('contend').from('y')

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
      model.valid().value.should.equal(true)

    it 'should return false if one or more active issues exist', ->
      class TestModel extends Model
        @attribute 'attr', class extends attribute.Attribute
          issues: -> new collection.List([ new Issue( active: this.watchValue() ) ])

        @attribute 'attr2', class extends attribute.Attribute
          issues: -> new collection.List([ new Issue( active: this.watchValue() ) ])

      model = new TestModel( attr: true, attr2: false )
      model.valid().value.should.equal(false)

      model.set('attr2', true)
      model.valid().value.should.equal(false)

      model.set('attr', false)
      model.set('attr2', false)
      model.valid().value.should.equal(true)

    it 'should take a severity threshold', ->
      class TestModel extends Model
        @attribute 'attr', class extends attribute.Attribute
          issues: ->
            new collection.List([
              new Issue( active: this.watchValue().map((val) -> val > 0), severity: 2 )
              new Issue( active: this.watchValue().map((val) -> val > 1), severity: 1 )
            ])

      model = new TestModel( attr: 0 )
      model.valid().value.should.equal(true)

      model.set('attr', 1)
      model.valid(1).value.should.equal(true)
      model.valid(2).value.should.equal(false)

      model.set('attr', 2)
      model.valid(1).value.should.equal(false)
      model.valid(2).value.should.equal(false)

