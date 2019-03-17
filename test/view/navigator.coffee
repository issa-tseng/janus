should = require('should')
{ match } = require('../../lib/view/navigator')
{ View } = require('../../lib/view/view')
{ Varying } = require('../../lib/core/varying')

# because Views have no implementation and so nobody actually renders subviews
# on them, and because the actual render mutator is a pain to deal with, we
# just invent our own subviewing simulator.
#
# !! VERY IMPORTANT !! the #add method is NOT meant to be used in the middle
# of assertions! it is NOT meant to mean "now this view has rendered a new
# child"! it is meant to perform INITIAL SETUP of the viewtree. using #add
# after query initialization violates fundamental assumptions internal to the
# framework.
class TreeView extends View
  _initialize: -> this._bindings = [ {}, {} ] # some dummies just to be sure
  add: (subject) ->
    view =
      if subject? then new TreeView(subject, { parent: this })
      else undefined
    this._bindings.push({ view: new Varying(view) })
    view

# these tests are /highly repetitive/ and very verbose. whatever. they're tests.
describe 'view navigator', ->
  describe 'selection', ->
    it 'should always return true given nothing', ->
      (match(undefined, 42) is true).should.equal(true)
      (match() is true).should.equal(true)

    it 'should return true given === match', ->
      (match(23, 23) is true).should.equal(true)
      (match('test', {}) is true).should.equal(false)

    it 'should return true given viewclass descendant', ->
      class A
      class B extends A
      (match(A, new B()) is true).should.equal(true)
      (match(B, new A()) is true).should.equal(false)

    it 'should return true given subjectclass descendant', ->
      class A
      class B extends A
      (match(A, { subject: new B() }) is true).should.equal(true)
      (match(B, { subject: new A() }) is true).should.equal(false)

    it 'should return false otherwise this is a stupid test', ->
      (match(1, 2) is true).should.equal(false)
      (match(0) is true).should.equal(false)

  describe 'into', ->
    describe 'primitive', ->
      it 'should return nothing given no present children', ->
        view = new TreeView()
        view.add()
        view.into().get_().should.eql([])

      it 'should return all matching views', ->
        class TestModel
        root = new TreeView()
        viewA = root.add(new TestModel())
        root.add(new TreeView())
        viewC = root.add(new TestModel())
        root.into(TestModel).get_().should.eql([ viewA, viewC ])

      it 'should search from multiple nodes', ->
        class TestModel
        root = new TreeView()
        children = []
        populate = (node) ->
          children.push(node.add(new TestModel()))
          node.add(23)
          children.push(node.add(new TestModel()))
        populate(root)
        populate(children[0])
        populate(children[1])

        result = root.into().into(TestModel).get_()
        result.length.should.equal(4)
        result.should.eql(children.slice(2))

    describe 'reactive', ->
      it 'should return nothing given no present children', ->
        view = new TreeView()
        view.add()
        view.into().get().length_.should.equal(0)

      it 'should correctly assess changing direct children', ->
        view = new TreeView()
        view.add()
        result = view.into(TreeView).get()

        child = new TreeView()
        view._bindings[2].view.set(child)
        result.length_.should.equal(1)
        result.get_(0).should.equal(child)

        class Dummy
        view._bindings[2].view.set(new Dummy())
        result.length_.should.equal(0)

      it 'should correctly assess changes from multiple nodes', ->
        class A
        class B extends A
        root = new TreeView()
        children = []
        populate = (node) ->
          children.push(node.add(new B()))
          node.add(23)
          children.push(node.add(new B()))
        populate(root)
        populate(children[0])
        populate(children[1])

        result = root.into().into(B).parent().get()
        result.length_.should.equal(2)
        result.get_(0).should.equal(children[0])
        result.get_(1).should.equal(children[1])

        root._bindings[2].view.set(new TreeView(new A()))
        result.length_.should.equal(1)
        result.get_(0).should.equal(children[1])

  describe 'parent', ->
    describe 'primitive', ->
      it 'should return nothing if the parent does not match', ->
        view = new TreeView('hello')
        child = view.add(12)
        child.parent(Number).get_().should.eql([])

      it 'should return the parent if it matches', ->
        parent = new TreeView('hello')
        child = parent.add(12)
        child.parent(TreeView).get_().should.eql([ parent ])

      it 'should search from multiple nodes', ->
        class A
        class B extends A
        root = new TreeView()
        children = []
        populate = (node) ->
          children.push(node.add(new A()))
          node.add(23)
          children.push(node.add(new B()))
        populate(root)
        populate(children[0])
        populate(children[1])

        root.into().into().parent(A).get_().should.eql([ children[0], children[1] ])
        root.into().into().parent(B).get_().should.eql([ children[1] ])

    describe 'reactive', ->
      it 'should return nothing if the parent does not match', ->
        view = new TreeView('hello')
        child = view.add(12)
        child.parent(Number).get().length_.should.equal(0)

      it 'should return the parent if it matches', ->
        view = new TreeView('hello')
        child = view.add(12)
        result = child.parent(TreeView).get()
        result.length_.should.equal(1)
        result.get_(0).should.equal(view)

      it 'should respond to changing conditions earlier in the query', ->
        class A
        class B extends A
        root = new TreeView()
        children = []
        populate = (node) ->
          children.push(node.add(new B()))
          node.add(23)
          children.push(node.add(new B()))
        populate(root)
        populate(children[0])
        populate(children[1])

        result = root.into(B).into().parent().get()
        result.length_.should.equal(2)
        result.get_(0).should.equal(children[0])
        result.get_(1).should.equal(children[1])

        root._bindings[2].view.set(new TreeView(new B()))
        result.length_.should.equal(1)
        result.get_(0).should.equal(children[1])

  describe 'closest', ->
    describe 'primitive', ->
      it 'should return nothing if all parents do not match', ->
        a = new TreeView('hello')
        b = a.add(12)
        c = b.add(24)
        c.closest(Boolean).get_().should.eql([])

      it 'should return the closest match', ->
        class A
        a = new TreeView(new A())
        b = a.add(12)
        c = b.add(24)
        c.closest(A).get_().should.eql([ a ])
        c.closest().get_().should.eql([ b ])

      it 'should search from multiple nodes', ->
        class A
        class B extends A
        root = new TreeView(new B())
        children = []
        populate = (node) ->
          children.push(node.add(new A()))
          node.add(23)
          children.push(node.add(new A()))
        populate(root)
        populate(children[0])
        populate(children[1])

        root.into().into().closest(B).get_().should.eql([ root ])
        root.into().into().closest(A).get_().should.eql([ children[0], children[1] ])

    describe 'reactive', ->
      it 'should return nothing if all parents do not match', ->
        a = new TreeView('hello')
        b = a.add(12)
        c = b.add(24)
        c.closest(Boolean).get().length_.should.equal(0)

      it 'should return the closest match', ->
        class A
        a = new TreeView(new A())
        b = a.add(12)
        c = b.add(24)
        c.closest(A).get().get_(0).should.equal(a)
        c.closest().get().get_(0).should.equal(b)

      it 'should respond to changing conditions earlier in the query', ->
        class A
        class B extends A
        root = new TreeView(new B())
        children = []
        populate = (node) ->
          children.push(node.add(new B()))
          node.add(23)
          children.push(node.add(new A()))
        populate(root)
        populate(children[0])
        populate(children[1])

        result = root.into(A).into().closest(B).get()
        result.length_.should.equal(2)
        result.get_(0).should.equal(children[0])
        result.get_(1).should.equal(root)

        root._bindings[2].view.set(new TreeView())
        result.length_.should.equal(1)
        result.get_(0).should.equal(root)

        newsubtree = new TreeView(new B())
        newsubtree.add(new A())
        root._bindings[2].view.set(newsubtree)
        result.length_.should.equal(2)
        result.get_(0).should.equal(root) # TODO: these assertions will need to be reversed when uniqlist order constancy is implemented.
        result.get_(1).should.equal(newsubtree)

  describe 'first/last', ->
    describe 'as terminus', ->
      it 'should return the correct view on get_', ->
        class A
        root = new TreeView(new A())
        first = root.add(new A())
        root.add(new A())
        last = root.add(new A())
        root.into().first().get_().should.equal(first)
        root.into().last().get_().should.equal(last)

      it 'should return Varying[the correct view] on get', ->
        class A
        root = new TreeView(new A())
        first = root.add(new A())
        second = root.add(new A())
        last = root.add(new A())

        results = []
        root.into().first().get().react((view) -> results.push('first', view))
        root.into().last().get().react((view) -> results.push('last', view))
        results.should.eql([ 'first', first, 'last', last ])

        root._bindings[2].view.set(null)
        results.should.eql([ 'first', first, 'last', last, 'first', second ])
        root._bindings[4].view.set(null)
        results.should.eql([ 'first', first, 'last', last, 'first', second, 'last', second ])

    describe 'as navigation', ->
      it 'should filter primitive queries', ->
        class A
        root = new TreeView(new A())
        children = []
        populate = (node) ->
          children.push(node.add(new A()))
          node.add(23)
          children.push(node.add(new A()))
        populate(root)
        populate(children[0])
        populate(children[1])

        root.into().first().into(A).get_().should.eql([ children[2], children[3] ])
        root.into().last().into(A).get_().should.eql([ children[4], children[5] ])

      it 'should return empty array given no upstream matches', ->
        node = new TreeView()
        node.into().first().into().get_().should.eql([])

      it 'should filter reactive queries (first)', ->
        class A
        root = new TreeView(new A())
        children = []
        populate = (node) ->
          children.push(node.add(new A()))
          node.add(23)
          children.push(node.add(new A()))
        populate(root)
        populate(children[0])
        populate(children[1])

        result = root.into(A).first().into(A).get()
        result.length_.should.equal(2)
        result.get_(0).should.equal(children[2])
        result.get_(1).should.equal(children[3])

        root._bindings[2].view.set(null)
        result.length_.should.equal(2)
        result.get_(0).should.equal(children[4])
        result.get_(1).should.equal(children[5])

      it 'should return empty list given no upstream matches', ->
        node = new TreeView()
        node.into().first().into().get().length_.should.equal(0)

      it 'should filter reactive queries (last)', ->
        class A
        root = new TreeView(new A())
        children = []
        populate = (node) ->
          children.push(node.add(new A()))
          node.add(23)
          children.push(node.add(new A()))
        populate(root)
        populate(children[0])
        populate(children[1])

        result = root.into(A).last().into(A).get()
        result.length_.should.equal(2)
        result.get_(0).should.equal(children[4])
        result.get_(1).should.equal(children[5])

        root._bindings[4].view.set(null)
        result.length_.should.equal(2)
        result.get_(0).should.equal(children[2])
        result.get_(1).should.equal(children[3])

