should = require('should')

Library = require('../../lib/library/library').Library

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

  describe 'registration', ->
    it 'should take a class and any book', ->
      library = new Library()

      class TestClass
      testBook = {}

      library.register(TestClass, testBook)

      should.exist(library.bookcase[Library._classId(TestClass)])

