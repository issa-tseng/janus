should = require('should')

Model = require('../../lib/model/model').Model

Varying = require('../../lib/core/varying').Varying
{ List } = require('../../lib/collection/list')

describe 'List', ->
  describe 'core', ->
    it 'should result in an empty list if directly constructed', ->
      l = new List()
      l.list.should.eql([])
      l.length_.should.equal(0)

    it 'should accept elements out of an array if provided', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      l.list.should.eql([ 4, 8, 15, 16, 23, 42 ])
      l.length_.should.equal(6)

    it 'should accept a nested array', ->
      l = new List([ [ 4, 8 ], [ 15, 16 ], [ 23, 42 ] ])
      l.list.should.eql([ [ 4, 8 ], [ 15, 16 ], [ 23, 42 ] ])
      l.length_.should.equal(3)

  describe 'retrieval', ->
    it 'should retrieve the element at idx', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      l.at_(0).should.equal(4)
      l.at_(2).should.equal(15)
      l.at_(5).should.equal(42)
      should(l.at_(6)).equal(undefined)

    it 'should retrieve the element at reverse idx if negative', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      l.at_(-1).should.equal(42)
      l.at_(-3).should.equal(16)
      l.at_(-6).should.equal(4)
      should(l.at_(-7)).equal(undefined)

    it 'should give the appropriate list length', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      l.length_.should.equal(6)

      l.add([ 56, 72, 99 ])
      l.length_.should.equal(9)

  describe 'addition', ->
    it 'should add single new elements at the end', ->
      l = new List([ 4, 8 ])

      l.add(15)
      l.length_.should.equal(3)
      for val, idx in [ 4, 8, 15 ]
        l.at_(idx).should.equal(val)

      l.add(16)
      l.length_.should.equal(4)
      for val, idx in [ 4, 8, 15, 16 ]
        l.at_(idx).should.equal(val)

    it 'should add elements past the end', ->
      l = new List([ 1 ])
      l.add(5, 4)
      l.length_.should.equal(5)
      for val, idx in [ 1, undefined, undefined, undefined, 5 ]
        should(l.at_(idx)).equal(val)

    it 'should add multiple new elements at the end', ->
      l = new List([ 4, 8 ])

      l.add([ 15, 16 ])
      l.length_.should.equal(4)
      for val, idx in [ 4, 8, 15, 16 ]
        l.at_(idx).should.equal(val)

      l.add([ 23, 42 ])
      l.length_.should.equal(6)
      for val, idx in [ 4, 8, 15, 16, 23, 42 ]
        l.at_(idx).should.equal(val)

    it 'should add single new elements in the middle', ->
      l = new List([ 4, 8, 16, 23, 42 ])

      l.add(15, 2)
      l.length_.should.equal(6)
      for val, idx in [ 4, 8, 15, 16, 23, 42 ]
        l.at_(idx).should.equal(val)

    it 'should add multiple new elements in the middle', ->
      l = new List([ 4, 8, 42 ])

      l.add([ 15, 16, 23 ], 2)
      l.length_.should.equal(6)
      for val, idx in [ 4, 8, 15, 16, 23, 42 ]
        l.at_(idx).should.equal(val)

    it 'should emit an event for each added element', ->
      l = new List([ 4, 8, 42 ])
      evented = []
      l.on('added', (elem, idx) -> evented.push(elem); evented.push(idx))

      l.add([ 15, 16, 23 ], 2)
      evented.should.eql([ 15, 2, 16, 3, 23, 4 ])

    it 'should emit an event on the added element if applicable', ->
      l = new List([ 1, 2 ])
      evented = []
      array =
        for idx in [0..2]
          do (idx) ->
            m = new Model()
            m.on('addedTo', (list, midx) ->
              list.should.equal(l)
              evented.push(idx)
              evented.push(midx)
            )
            m

      l.add(array)
      evented.should.eql([ 0, 2, 1, 3, 2, 4 ])

  describe 'set', ->
    it 'should overwrite the appropriate element', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      l.set(2, 'hi')
      l.length_.should.equal(6)
      for val, idx in [ 4, 8, 'hi', 16, 23, 42 ]
        l.at_(idx).should.equal(val)

    it 'should be able to set past the end of the list', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      l.set(7, 'hi')
      l.length_.should.equal(8)
      for val, idx in [ 4, 8, 15, 16, 23, 42, undefined, 'hi' ]
        (l.at_(idx) is val).should.equal(true)

    it 'should accept negative indices', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      l.set(-3, 'hi')
      l.length_.should.equal(6)
      for val, idx in [ 4, 8, 15, 'hi', 23, 42 ]
        l.at_(idx).should.equal(val)

    it 'should emit add events', ->
      results = []
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      l.on('added', (obj, idx) -> results.push([ obj, idx ]))

      l.set(-2, 'red')
      l.set(0, 'blue')

      results.should.eql([
        [ 'red', 4 ],
        [ 'blue', 0 ]
      ])

    it 'should emit removal events, only if a value was removed', ->
      results = []
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      l.on('removed', (obj, idx) -> results.push([ obj, idx ]))

      l.set(10, 'hello')
      l.set(2, 'good day')

      results.should.eql([ [ 15, 2 ] ])

  describe 'automated removal', ->
    it 'should remove Base elements that are destroyed', ->
      eventedElem = null
      eventedIdx = null
      l = new List(new Model() for _ in [0..4])
      l.on('removed', (elem, idx) -> eventedElem = elem; eventedIdx = idx)

      m = l.at_(2)
      m.destroy()
      eventedElem.should.equal(m)
      eventedIdx.should.equal(2)
      l.length_.should.equal(4)

    it 'should not remove destroying Base elements if the list is derived', -> # gh97
      l = new List(new Model() for _ in [0..4])
      m = l.map((x) -> x.shadow())
      should.doesNotThrow(-> m.at_(0).destroy())
      # in the wild, this occurs when views self-destroy; we just destroy m to simulate this.

  describe 'removal (reference)', ->
    it 'should remove elements by reference', ->
      obj = {}
      l = new List([ {}, 2, 'test', obj, {} ])

      l.remove(2)
      l.length_.should.equal(4)
      for val, idx in [ {}, 'test', {}, {} ]
        l.at_(idx).should.eql(val)

      l.remove(obj)
      l.length_.should.equal(3)
      l.at_(2).should.not.equal(obj)
      l.at_(2).should.eql({})

    it 'should return undefined if the element is not found', ->
      l = new List()
      should(l.remove(0)).equal(undefined)

    it 'should return the removed element', ->
      obj = {}
      l = new List([ {}, {}, obj, {} ])
      l.remove(obj).should.equal(obj)

    it 'should event upon removal', ->
      obj = {}
      eventedElem = eventedIdx = null
      l = new List([ {}, {}, obj, {} ])
      l.on('removed', (elem, idx) -> eventedElem = elem; eventedIdx = idx)

      l.remove(obj)
      eventedElem.should.equal(obj)
      eventedIdx.should.equal(2)

  describe 'removal (index)', ->
    it 'should remove the element indicated by the index', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      l.removeAt(2)
      l.length_.should.equal(4)
      for val, idx in [ 1, 2, 4, 5 ]
        l.at_(idx).should.equal(val)

    it 'should return the element that was removed', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      l.removeAt(0).should.equal(1) # first
      l.removeAt(2).should.equal(4) # middle
      l.removeAt(2).should.equal(5) # last

    it 'should remove an element by reverse index', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      l.removeAt(-1).should.equal(5)
      l.removeAt(-3).should.equal(2)

    it 'should abort on out of bounds', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      should(l.removeAt(5)).equal(undefined)
      should(l.removeAt(-6)).equal(undefined)
      l.length_.should.equal(5)

    it 'should event upon removal', ->
      removed = []
      l = new List([ 1, 2, 3, 4, 5 ])
      l.on('removed', (elem, idx) -> removed.push(elem); removed.push(idx))
      l.remove(2)
      l.removeAt(-1)
      removed.should.eql([ 2, 1, 5, 3 ])

    it 'should event on the removed object if applicable', ->
      eventedList = eventedIdx = null
      m = new Model()
      m.on('removedFrom', (list, idx) -> eventedList = list; eventedIdx = idx)

      l = new List([ 1, 2, m, 4, 5 ])
      l.remove(m)
      eventedList.should.equal(l)
      eventedIdx.should.equal(2)

  describe 'move', ->
    it 'should move the element to the relevant place', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      l.move(4, 0)
      l.length_.should.equal(5)
      for val, idx in [ 4, 1, 2, 3, 5 ]
        l.at_(idx).should.equal(val)

      l.move(4, 2)
      l.length_.should.equal(5)
      for val, idx in [ 1, 2, 4, 3, 5 ]
        l.at_(idx).should.equal(val)

    it 'should abort if the element is not found', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      should(l.move(6, 0)).equal(undefined)
      l.length_.should.equal(5)

    it 'should event on the list', ->
      eventedArgs = []
      l = new List([ 1, 2, 3, 4, 5 ])
      l.on('moved', (args...) -> eventedArgs.push(arg) for arg in args)
      l.move(1, 4)
      eventedArgs.should.eql([ 1, 4, 0 ])

    it 'should event on the moved object if relevant', ->
      eventedArgs = []
      m = new Model()
      l = new List([ m, 2, 3, 4, 5 ])
      m.on('movedIn', (args...) -> eventedArgs.push(arg) for arg in args)
      l.move(m, 2)
      eventedArgs.should.eql([ l, 2, 0 ])

  describe 'moveAt', ->
    it 'should move the element to the relevant place', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      l.moveAt(2, 0)
      l.length_.should.equal(5)
      for val, idx in [ 3, 1, 2, 4, 5 ]
        l.at_(idx).should.equal(val)

    it 'should allow negative indices', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      l.moveAt(-1, -3)
      l.length_.should.equal(5)
      for val, idx in [ 1, 2, 5, 3, 4 ]
        l.at_(idx).should.equal(val)

  describe 'removeAll', ->
    it 'should remove all elements', ->
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      l.removeAll()
      l.length_.should.equal(0)

    it 'should return the removed elements', ->
      (new List([ 4, 8, 15, 16, 23, 42 ])).removeAll().should.eql([ 4, 8, 15, 16, 23, 42 ])

    it 'should event for each removed element', ->
      evented = []
      l = new List([ 4, 8, 15, 16, 23, 42 ])
      l.on('removed', (args...) -> evented.push(arg) for arg in args)
      l.removeAll()
      evented.should.eql([ 4, 0, 8, 0, 15, 0, 16, 0, 23, 0, 42, 0 ])

    it 'should event on each removed element if applicable', ->
      eventedArgs = []
      ms =
        for idx in [0..2]
          do (idx) ->
            m = new Model()
            m.on('removedFrom', (args...) -> args.push(idx); eventedArgs.push(arg) for arg in args)
            m
      l = new List(ms)
      l.removeAll()
      eventedArgs.should.eql([ l, 0, 0, l, 0, 1, l, 0, 2 ])

  describe 'at', ->
    it 'should watch the value at an index', ->
      l = new List([ 1, 2, 3 ])
      results = []
      l.at(4).react((x) -> results.push(x))
      l.add(4) # 1, 2, 3, 4
      l.add(5) # 1, 2, 3, 4, *5
      l.add(0, 0) # 0, 1, 2, 3, *4, 5
      l.add(6) # 0, 1, 2, 3, *4, 5, 6
      l.removeAt(4) # 0, 1, 2, 3, *5, 6
      l.moveAt(1, 4) # 0, 2, 3, 5, *1, 6
      l.moveAt(4, 0) # 1, 0, 2, 3, *5, 6
      l.moveAt(2, 5) # 1, 0, 3, 5, *6, 2
      l.moveAt(5, 0) # 2, 1, 0, 3, *5, 6
      results.should.eql([ undefined, 5, 4, 5, 1, 5, 6, 5 ])

    it 'should watch the value at a reverse index', ->
      l = new List([ 1, 2, 3, 4 ])
      results = []
      l.at(-5).react((x) -> results.push(x))
      l.add(5) # *1, 2, 3, 4, 5
      l.add(0, 0) # 0, *1, 2, 3, 4, 5
      l.add(1.5, 2) # 0, 1, *1.5, 2, 3, 4, 5
      l.removeAt(0) # 1, *1.5, 2, 3, 4, 5
      l.removeAt(-1) # *1, 1.5, 2, 3, 4
      l.add(0, 0) # 0, *1, 1.5, 2, 3, 4 # this line is really just to be able to fully test move.
      l.moveAt(1, 3) # 0, *1.5, 2, 1, 3, 4
      l.moveAt(4, 1) # 0, *3, 1.5, 2, 1, 4
      l.moveAt(0, 4) # 3, *1.5, 2, 1, 0, 4
      l.moveAt(5, 0) # 4, *3, 1.5, 2, 1, 0
      results.should.eql([ undefined, 1, 1.5, 1, 1.5, 3, 1.5, 3 ])

    it 'should watch the last value correctly', ->
      l = new List([ 1, 2, 3, 4 ])
      results = []
      l.at(-1).react((x) -> results.push(x))
      l.removeAt(-1)
      results.should.eql([ 4, 3 ])

    it 'should be able to take a Varying index to watch', ->
      results = []
      l = new List([ 1, 2, 3, 4 ])
      v = new Varying(2)
      l.at(v).react((x) -> results.push(x))
      l.removeAt(1) # 1 3 *4
      v.set(0) # *1 3 4
      l.add(0, 0) # *0 1 3 4
      results.should.eql([ 3, 4, 1, 0 ])

  describe 'length', ->
    it 'should watch the length of the list', ->
      l = new List([ 1, 2, 3, 4 ])
      results = []
      l.length.react((x) -> results.push(x))
      l.add(5)
      l.add([ 6, 7 ])
      l.removeAt(0)
      l.removeAt(1)
      results.should.eql([ 4, 5, 7, 6, 5 ])

    it 'should provide an empty_ convenience method', ->
      (new List()).empty_().should.equal(true)
      (new List(0)).empty_().should.equal(false)

    it 'should provide an empty convenience method', ->
      l = new List()
      result = null
      l.empty().react((x) -> result = x)
      result.should.equal(true)
      l.add(2)
      result.should.equal(false)
      l.removeAt(0)
      result.should.equal(true)

    it 'should provide a nonEmpty_ convenience method', ->
      (new List()).nonEmpty_().should.equal(false)
      (new List(0)).nonEmpty_().should.equal(true)

    it 'should provide a nonEmpty convenience method', ->
      l = new List()
      result = null
      l.nonEmpty().react((x) -> result = x)
      result.should.equal(false)
      l.add(2)
      result.should.equal(true)
      l.removeAt(0)
      result.should.equal(false)

  describe 'iteration', ->
    it 'should conform to the ES6 iterator protocol for direct iteration', -> # gh102
      return if typeof Symbol is 'undefined' # we aren't in ES6
      (new List())[Symbol.iterator]().next.should.be.a.Function()

  describe 'deserialize', ->
    it 'should use the provided modelClass if it has a deserialize class method', ->
      class TestModel extends Model
        @deserialize: -> 42

      class TestList extends List
        @modelClass: TestModel

      TestList.deserialize([ 1, 2, 3, 4 ]).list.should.eql([ 42, 42, 42, 42 ])

    it 'should simply take the array if the modelClass does not have a deserialized class method', ->
      class TestModel extends Model
        @deserialize: undefined

      class TestList extends List
        @modelClass: TestModel

      TestList.deserialize([ 1, 2, 3, 4 ]).list.should.eql([ 1, 2, 3, 4 ])

  describe 'of', ->
    it 'should set the modelClass property', ->
      class TestModel extends Model
      TestList = List.of(TestModel)
      TestList.modelClass.should.equal(TestModel)

    it 'should deserialize as the given model', ->
      class TestModel extends Model
      TestList = List.of(TestModel)

      result = TestList.deserialize([ { a: 1 }, { b: 2 } ]).list
      result[0].should.be.an.instanceof(TestModel)
      result[0].get_('a').should.equal(1)
      result[1].should.be.an.instanceof(TestModel)
      result[1].get_('b').should.equal(2)


