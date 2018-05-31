should = require('should')

Library = require('../../lib/application/library').Library
{ defcase } = require('../../lib/core/case')

describe 'Library', ->
  describe 'core', ->
    it 'should construct', ->
      (new Library()).should.be.an.instanceof(Library)

  describe 'class identification', ->
    it 'should return an integer', ->
      class TestClass
      (typeof Library._classId(TestClass) is 'number').should.be.true

    it 'should tag the class with the id', ->
      class TestClass

      id = Library._classId(TestClass)
      TestClass[Library.classKey].should.equal(id)

    it 'should return the same id for a class each time', ->
      class TestClass

      Library._classId(TestClass).should.equal(Library._classId(TestClass))

    it 'should return a different id for a derived class', ->
      class ClassA
      class ClassB extends ClassA

      Library._classId(ClassA).should.not.equal(Library._classId(ClassB))

    it 'should return "null" for null', ->
      Library._classId(null).should.equal('null')
    it 'should return "case@#ns" for a case', ->
      { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
      Library._classId(success).should.equal('case@org.janusjs.test.success')
      Library._classId(success(42)).should.equal('case@org.janusjs.test.success')
    it 'should return "number" for Number', ->
      Library._classId(Number).should.equal('number')
    it 'should return "string" for String', ->
      Library._classId(String).should.equal('string')
    it 'should return "boolean" for Boolean', ->
      Library._classId(Boolean).should.equal('boolean')

  describe 'registration', ->
    it 'should take a class and any book', ->
      library = new Library()
      class TestClass

      library.register(TestClass, {})

      should.exist(library.bookcase[Library._classId(TestClass)]?.default?[0])

  describe 'retrieval', ->
    it 'should return a book for its class with no description', ->
      library = new Library()

      class TestBook
      class TestObj
      library.register(TestObj, TestBook)

      library.get(new TestObj()).should.be.an.instanceof(TestBook)

    it 'should return a book for its superclass with no description', ->
      library = new Library()

      class TestBook
      class TestObj
      class TestSubObj extends TestObj
      library.register(TestObj, TestBook)

      library.get(new TestSubObj()).should.be.an.instanceof(TestBook)

    it 'should return a book against a null registration', ->
      library = new Library()

      class TestBook
      library.register(null, TestBook)

      library.get(null).should.be.an.instanceof(TestBook)

    it 'should handle multiple available registrations', ->
      library = new Library()

      class TestBookA
      class TestObjA
      library.register(TestObjA, TestBookA)

      class TestBookB
      class TestObjB
      library.register(TestObjB, TestBookB)

      library.get(new TestObjA()).should.be.an.instanceof(TestBookA)
      library.get(new TestObjB()).should.be.an.instanceof(TestBookB)

    it 'should deal with contexts', ->
      library = new Library()

      class TestBook
      class TestObj

      library.register(TestObj, TestBook, context: 'edit')

      should.not.exist(library.get(new TestObj()))
      library.get(new TestObj(), context: 'edit').should.be.an.instanceof(TestBook)

    it 'should handle priority correctly', ->
      library = new Library()
      class TestObj

      class TestBookA
      library.register(TestObj, TestBookA)
      library.get(new TestObj()).should.be.an.instanceof(TestBookA)

      class TestBookB
      library.register(TestObj, TestBookB, priority: 50)
      library.get(new TestObj()).should.be.an.instanceof(TestBookB)

      class TestBookC
      library.register(TestObj, TestBookC, priority: 25)
      library.get(new TestObj()).should.be.an.instanceof(TestBookB)

    it 'should handle attributes correctly', ->
      library = new Library()

      class TestObj
      class TestBook
      library.register(TestObj, TestBook, attributes: { style: 'button' })

      library.get(new TestObj()).should.be.an.instanceof(TestBook)
      library.get(new TestObj(), attributes: { style: 'button' }).should.be.an.instanceof(TestBook)
      should.not.exist(library.get(new TestObj(), attributes: { style: 'link' }))


    it 'should handle acceptors correctly', ->
      library = new Library()

      class TestObj
      class TestBook
      library.register(TestObj, TestBook, acceptor: (obj) -> obj.accept is true)

      should.not.exist(library.get(new TestObj()))

      obj = new TestObj()
      obj.accept = true
      library.get(obj).should.be.an.instanceof(TestBook)


    it 'should handle rejectors correctly', ->
      library = new Library()

      class TestObj
      class TestBook
      library.register(TestObj, TestBook, rejector: (obj) -> obj.accept isnt true)

      should.not.exist(library.get(new TestObj()))

      obj = new TestObj()
      obj.accept = true
      library.get(obj).should.be.an.instanceof(TestBook)

    it 'should return lower priority results if higher ones fail', ->
      library = new Library()
      class TestObj

      class TestBookA
      library.register(TestObj, TestBookA, priority: 10, acceptor: (obj) -> obj.accept is true)

      class TestBookB
      library.register(TestObj, TestBookB, priority: 5)

      obj = new TestObj()
      obj.accept = true
      library.get(obj).should.be.an.instanceof(TestBookA)

      obj.accept = false
      library.get(obj).should.be.an.instanceof(TestBookB)

  describe 'case registration', ->
    it 'should store and retrieve cases correctly', ->
      library = new Library()
      { success, fail } = defcase('org.janusjs.test', 'success', 'fail')

      class SuccessBook
      library.register(success, SuccessBook)

      library.get(success(42)).should.be.an.instanceof(SuccessBook)
      library.get(success).should.be.an.instanceof(SuccessBook)
      should(library.get(fail)).equal(null)

    it 'should not conflate like-named cases from different sets', ->
      library = new Library()
      set1 = defcase('org.janusjs.test', 'success', 'fail')
      set2 = defcase('org.janusjs.test2', 'success', 'fail')

      class SuccessBook
      library.register(set1.success, SuccessBook)

      should(library.get(set2.success(42))).equal(null)
      should(library.get(set2.success)).equal(null)

  describe 'events', ->
    it 'should emit a got event when a book is retrieved', ->
      library = new Library()

      class TestObj
      class TestBook
      library.register(TestObj, TestBook)

      obj = new TestObj()
      options = {}

      evented = false
      library.on 'got', (result, obj2, book, options2) ->
        result.should.be.an.instanceof(TestBook)
        obj2.should.equal(obj)
        book.should.equal.TestBook
        options2.should.equal(options)
        evented = true

      library.get(obj, options)
      evented.should.be.true

    it 'should emit a missed event when nothing is retrieved', ->
      library = new Library()

      class TestObjA
      class TestObjB
      class TestBook
      library.register(TestObjA, TestBook)

      obj = new TestObjB()
      options = {}

      evented = false
      library.on 'missed', (obj2, options2) ->
        obj2.should.equal(obj)
        options2.should.equal(options)
        evented = true

      library.get(obj, options)
      evented.should.be.true

