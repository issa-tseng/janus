should = require('should')

Library = require('../../lib/application/library').Library
{ Case } = require('../../lib/core/case')

describe 'Library', ->
  describe 'core', ->
    it 'should construct', ->
      (new Library()).should.be.an.instanceof(Library)

  describe 'class identification', ->
    it 'should return an integer', ->
      class TestClass
      (typeof Library._classId(TestClass) is 'number').should.equal(true)

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
    it 'should return int for a case', ->
      { success, fail } = Case.build('success', 'fail')
      Library._classId(success).should.be.a.Number()
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

      library.get(new TestObj()).should.equal(TestBook)

    it 'should return a book for its superclass with no description', ->
      library = new Library()

      class TestBook
      class TestObj
      class TestSubObj extends TestObj
      library.register(TestObj, TestBook)

      library.get(new TestSubObj()).should.equal(TestBook)

    it 'should return a book against a null registration', ->
      library = new Library()

      class TestBook
      library.register(null, TestBook)

      library.get(null).should.equal(TestBook)

    it 'should handle multiple available registrations', ->
      library = new Library()

      class TestBookA
      class TestObjA
      library.register(TestObjA, TestBookA)

      class TestBookB
      class TestObjB
      library.register(TestObjB, TestBookB)

      library.get(new TestObjA()).should.equal(TestBookA)
      library.get(new TestObjB()).should.equal(TestBookB)

    it 'should deal with contexts', ->
      library = new Library()

      class TestBook
      class TestObj

      library.register(TestObj, TestBook, context: 'edit')

      should.not.exist(library.get(new TestObj()))
      library.get(new TestObj(), context: 'edit').should.equal(TestBook)

    it 'should handle priority correctly', ->
      library = new Library()
      class TestObj

      class TestBookA
      library.register(TestObj, TestBookA)
      library.get(new TestObj()).should.equal(TestBookA)

      class TestBookB
      library.register(TestObj, TestBookB, priority: 50)
      library.get(new TestObj()).should.equal(TestBookB)

      class TestBookC
      library.register(TestObj, TestBookC, priority: 25)
      library.get(new TestObj()).should.equal(TestBookB)

    it 'should match against custom attributes correctly', ->
      library = new Library()

      class TestObj
      class TestBook
      library.register(TestObj, TestBook, { style: 'button' })

      library.get(new TestObj()).should.equal(TestBook)
      library.get(new TestObj(), { style: 'button' }).should.equal(TestBook)
      should.not.exist(library.get(new TestObj(), { style: 'link' }))

    it 'should return lower priority results if higher ones fail', ->
      library = new Library()
      class TestObj

      class TestBookX
      library.register(TestObj, TestBookX, priority: 1)

      class TestBookA
      library.register(TestObj, TestBookA, priority: 10, condition: 'value')

      class TestBookB
      library.register(TestObj, TestBookB, priority: 5, condition: 'else')

      library.get(new TestObj()).should.equal(TestBookA)
      library.get(new TestObj(), { condition: 'else' }).should.equal(TestBookB)

  describe 'case registration', ->
    it 'should store and retrieve cases correctly', ->
      library = new Library()
      { success, fail } = Case.build('success', 'fail')

      class SuccessBook
      library.register(success, SuccessBook)
      console.log(Library._classId(success))

      library.get(success(42)).should.equal(SuccessBook)
      should(library.get(fail)).equal(null)

    it 'should not conflate like-named cases from different sets', ->
      library = new Library()
      set1 = Case.build('success', 'fail')
      set2 = Case.build('success', 'fail')

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
      library.on 'got', (obj2, book, options2) ->
        obj2.should.equal(obj)
        book.should.equal(TestBook)
        options2.should.equal(options)
        evented = true

      library.get(obj, options)
      evented.should.equal(true)

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
      evented.should.equal(true)

