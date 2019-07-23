should = require('should')
{ match } = require('../../lib/view/navigation')
{ Model } = require('../../lib/model/model')
{ List } = require('../../lib/collection/list')
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

# and here, we create a thin mock for how the stdlib ListView works.
# it takes a list of views and mocks up the correct structure to look like bindings for them.
class ListView extends View
  constructor: (list) ->
    this._mappedBindings = list.map((view) -> (new Varying(view)).react(->))

# these tests are /highly repetitive/ and very verbose. whatever. they're tests.
describe 'view navigation', ->
  describe 'selection', ->
    it 'should always return true given nothing', ->
      (match(undefined, 42) is true).should.equal(true)
      (match() is true).should.equal(true)

    it 'should return true given === match', ->
      (match(23, 23) is true).should.equal(true)
      (match('test', {}) is true).should.equal(false)

    it 'should return true given === subject match', ->
      (match(23, { subject: 23 }) is true).should.equal(true)

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

  describe 'into_', ->
    it 'should return nothing given no present children', ->
      view = new TreeView()
      view.add()
      should.not.exist(view.into_())

    it 'should return the first matching view', ->
      class TestModel
      root = new TreeView()
      viewA = root.add(new TestModel())
      root.add(new TreeView())
      viewC = root.add(new TestModel())
      root.into_(TestModel).should.equal(viewA)

    it 'should search by data key', ->
      modelA = new Model()
      modelB = new Model()
      root = new TreeView(new Model({ x: modelA, y: modelB }))
      viewA = root.add(modelA)
      viewB = root.add(modelB)
      root.into_('x').should.equal(viewA)
      root.into_('y').should.equal(viewB)

    it 'should work with stdlib ListViews', ->
      class A
      class B
      viewA = new TreeView(A)
      viewB = new TreeView(A)
      subviews = new List([ viewA, new TreeView(B), null, viewB ])
      listView = new ListView(subviews)
      root = new TreeView()
      root._bindings.push({ view: new Varying(listView) })

      root.into_().into_(A).should.equal(viewA)

  describe 'into', ->
    # specific cases are more heavily tested under intoAll below, as into is just
    # intoAll(…).get(0)
    it 'should return nothing given no present children', ->
      view = new TreeView()
      view.add()
      should.not.exist(view.into().get())

    it 'should return the first match if it exists', ->
      view = new TreeView()
      view.add()
      view.add()
      result = view.into(TreeView)

      child = new TreeView()
      view._bindings[2].view.set(child)
      result.get().should.equal(child)

      class Dummy
      view._bindings[2].view.set(new Dummy())
      should.not.exist(result.get())

      newChild = new TreeView()
      view._bindings[3].view.set(newChild)
      result.get().should.equal(newChild)

      view._bindings[2].view.set(child)
      result.get().should.equal(child)

  describe 'intoAll_', ->
    it 'should return all matching views', ->
      class TestModel
      root = new TreeView()
      viewA = root.add(new TestModel())
      root.add(new TreeView())
      viewC = root.add(new TestModel())
      root.intoAll_(TestModel).should.eql([ viewA, viewC ])

    it 'should search by data key', ->
      modelA = new Model()
      modelB = new Model()
      root = new TreeView(new Model({ x: modelA, y: modelB }))
      viewA = root.add(modelA)
      viewB = root.add(modelB)
      root.intoAll_('x').should.eql([ viewA ])
      root.intoAll_('y').should.eql([ viewB ])
      root.intoAll_('z').should.eql([])

    it 'should work with stdlib ListViews', ->
      class A
      class B
      viewA = new TreeView(A)
      viewB = new TreeView(A)
      subviews = new List([ viewA, new TreeView(B), null, viewB ])
      listView = new ListView(subviews)
      root = new TreeView()
      root._bindings.push({ view: new Varying(listView) })

      root.into_().intoAll_(A).should.eql([ viewA, viewB ])

  describe 'intoAll', ->
    it 'should return empty given no present children', ->
      view = new TreeView()
      view.add()
      view.intoAll().length_.should.equal(0)

    it 'should correctly assess changing direct children', ->
      view = new TreeView()
      view.add()
      view.add()
      result = view.intoAll(TreeView)

      childA = new TreeView()
      view._bindings[2].view.set(childA)
      result.length_.should.equal(1)
      result.get_(0).should.equal(childA)

      childB = new TreeView()
      view._bindings[3].view.set(childB)
      result.length_.should.equal(2)
      result.get_(1).should.equal(childB)

      class Dummy
      view._bindings[2].view.set(new Dummy())
      view._bindings[3].view.set(new Dummy())
      result.length_.should.equal(0)

    it 'should correctly assess changing selector', ->
      class A
      class B
      view = new TreeView()
      childA = new A()
      view.add(childA)
      childB = new B()
      view.add(childB)

      sel = new Varying(A)
      result = view.intoAll(sel)
      result.length_.should.equal(1)
      result.get_(0).subject.should.equal(childA)

      sel.set(B)
      result.length_.should.equal(1)
      result.get_(0).subject.should.equal(childB)

      view._bindings[2].view.set(new B())
      result.length_.should.equal(2)
      result.get_(1).subject.should.be.an.instanceof(B)


    it 'should search by data key', ->
      childModel = new Model()
      parentModel = new Model({ x: childModel, y: new Model() })
      root = new TreeView(parentModel)
      viewA = root.add(childModel)
      viewB = root.add(new Model())
      result = root.intoAll('x')
      result.length_.should.equal(1)
      result.get_(0).should.equal(viewA)

      viewC = new TreeView(childModel)
      root._bindings[3].view.set(viewC)
      result.length_.should.equal(2)
      result.get_(0).should.equal(viewA)
      result.get_(1).should.equal(viewC)

      parentModel.set('x', 42)
      result.length_.should.equal(0)

    it 'should work with stdlib ListViews', ->
      class A
      class B
      viewA = new TreeView(A)
      viewB = new TreeView(A)
      subviews = new List([ viewA, new TreeView(B), null, viewB ])
      listView = new ListView(subviews)

      result = listView.intoAll(A)
      result.length_.should.equal(2)
      result.get_(0).should.equal(viewA)
      result.get_(1).should.equal(viewB)

      viewC = new TreeView(A)
      subviews.add(viewC)
      result.length_.should.equal(3)
      result.get_(2).should.equal(viewC)

      subviews.remove(viewB)
      result.length_.should.equal(2)
      result.get_(0).should.equal(viewA)
      result.get_(1).should.equal(viewC)

  describe 'parent_', ->
    it 'should return nothing if the parent does not match', ->
      view = new TreeView('hello')
      child = view.add(12)
      should.not.exist(child.parent_(Number))

    it 'should return the parent if it matches', ->
      parent = new TreeView('hello')
      child = parent.add(12)
      child.parent_(TreeView).should.equal(parent)

  describe 'parent', ->
    it 'should return nothing if the parent does not match', ->
      view = new TreeView('hello')
      child = view.add(12)
      should.not.exist(child.parent(Number).get())

    it 'should return the parent if it matches', ->
      view = new TreeView('hello')
      child = view.add(12)
      child.parent(TreeView).get().should.equal(view)

  describe 'closest_', ->
    it 'should return nothing if all parents do not match', ->
      a = new TreeView('hello')
      b = a.add(12)
      c = b.add(24)
      should.not.exist(c.closest_(Boolean))

    it 'should return the closest match', ->
      class A
      a = new TreeView(new A())
      b = a.add(12)
      c = b.add(24)
      c.closest_(A).should.equal(a)
      c.closest_().should.equal(b)

  describe 'closest', ->
    it 'should return nothing if all parents do not match', ->
      a = new TreeView('hello')
      b = a.add(12)
      c = b.add(24)
      should.not.exist(c.closest(Boolean).get())

    it 'should return the closest match', ->
      class A
      a = new TreeView(new A())
      b = a.add(12)
      c = b.add(24)
      c.closest(A).get().should.equal(a)
      c.closest().get().should.equal(b)

