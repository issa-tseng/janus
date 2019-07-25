should = require('should')

{ Varying, DomView, template, find, from, List, Set, App, Library, Model } = require('janus')
{ ListView, SetView } = require('../../lib/view/list')

$ = require('janus-dollar')

# TODO: there is some kind of bug (i'm pretty sure it's not us, and it's not jquery,
# and it is domino) that shuffles this textnode to the end if i put it exactly here,
# and omits it if i put it at the end. weird. so all the assertions work off this.
class TestModel extends Model
TestModelView = DomView.build($('
    <div class="model-name"/>
    textnode
    <div class="model-length"/>
  '), template(
    find('.model-name').text(from('name'))
    find('.model-length').text(from.subject().flatMap((m) -> m.length))
))

# register TestModelView and LiteralView for our tests to make our lives easier.
testLibrary = new Library()
testLibrary.register(TestModel, TestModelView)
require('../../lib/view/literal').registerWith(testLibrary)
testApp = new App( views: testLibrary )

checkLiteral = (dom, expectedText) ->
  dom.is('span').should.equal(true)
  dom.hasClass('janus-literal').should.equal(true)
  dom.text().should.equal(expectedText.toString())

checkTestModel = (listDom, idx, model) ->
  listDom.contents().eq(idx).is('div.model-name').should.equal(true)
  listDom.contents().eq(idx).text().should.equal(model.get_('name'))
  listDom.contents().eq(idx + 1).is('div.model-length').should.equal(true)
  listDom.contents().eq(idx + 1).text().should.equal(model.length_.toString())
  listDom.contents()[idx + 2].nodeType.should.equal(3)
  listDom.contents()[idx + 2].outerHTML.should.equal(' textnode ')

describe 'view', ->
  describe 'list', ->
    describe 'render', ->
      it 'should render an unordered list element of the appropriate class', ->
        dom = (new ListView(new List())).artifact()
        dom.is('div').should.equal(true)
        dom.hasClass('janus-list').should.equal(true)

      it 'should initially display the appropriate elements', ->
        dom = (new ListView(new List([ 1, 2, 3 ]), { app: testApp })).artifact()
        dom.children().length.should.equal(3)

        for i in [0..2]
          child = dom.children().eq(i)
          checkLiteral(child, i + 1)

      it 'should initially render multi-root subviews', ->
        model = new TestModel( name: 'test' )
        l = new List([ 1, model, 3 ])
        dom = (new ListView(l, { app: testApp })).artifact()
        dom.contents().length.should.equal(5)

        checkLiteral(dom.contents().eq(0), 1)
        checkTestModel(dom, 1, model)
        checkLiteral(dom.contents().eq(4), 3)

      it 'should correctly add new elements', ->
        l = new List([ 1, 2, 3 ])
        dom = (new ListView(l, { app: testApp })).artifact()

        l.add(4)
        dom.children().length.should.equal(4)
        checkLiteral(dom.children(':last-child'), 4)

        l.add(5, 1)
        dom.children().length.should.equal(5)
        checkLiteral(dom.children().eq(1), 5)

      it 'should correctly block add new elements', ->
        l = new List([ 1, 2, 3 ])
        dom = (new ListView(l, { app: testApp })).artifact()

        l.add([ 4, 5, 6 ])
        dom.children().length.should.equal(6)
        checkLiteral(dom.children().eq(3), 4)
        checkLiteral(dom.children().eq(4), 5)
        checkLiteral(dom.children().eq(5), 6)

      it 'should deal correctly with missing views', ->
        # ie mostly if a library can't find a view for a thing.
        class A
        l = new List([ 1, 2, new A(), new A() ])
        dom = (new ListView(l, { app: testApp })).artifact()

        dom.children().length.should.equal(2)
        for label, idx in [ 1, 2 ]
          checkLiteral(dom.children().eq(idx), label)

        l.add(3, 2) # 1 2 3 A A
        dom.children().length.should.equal(3)
        for label, idx in [ 1, 2, 3 ]
          checkLiteral(dom.children().eq(idx), label)

        l.add(5, 4) # 1 2 3 A 5 A
        dom.children().length.should.equal(4)
        for label, idx in [ 1, 2, 3, 5 ]
          checkLiteral(dom.children().eq(idx), label)

        l.set(3, 4) # 1 2 3 4 5 A
        dom.children().length.should.equal(5)
        for label, idx in [ 1, 2, 3, 4, 5 ]
          checkLiteral(dom.children().eq(idx), label)

      it 'should handle reverse-order additions', ->
        # this can happen because although we provide the illusion of purity, the
        # tyranny of time means that we /have/ to propagate either reactions or
        # events first (we chose reactions). listview relies on events.
        l = new List([ true, false, true ])
        dom = (new ListView(l, { app: testApp })).artifact()

        l.at(-1).react((x) -> l.add(true) if x isnt true)

        l.add(false)
        l.list.should.eql([ true, false, true, false, true ])
        dom.children().length.should.equal(5)
        for label, idx in [ true, false, true, false, true ]
          checkLiteral(dom.children().eq(idx), label)

      it 'should correctly add multi-root subviews', ->
        l = new List([ 1, 2 ])
        dom = (new ListView(l, { app: testApp })).artifact()

        ma = new TestModel( name: 'ma' )
        l.add(ma, 1)
        dom.contents().length.should.equal(5)
        checkTestModel(dom, 1, ma)

        mb = new TestModel( name: 'mb', x: 0 )
        l.add(mb, 1)
        dom.contents().length.should.equal(8)
        checkTestModel(dom, 1, mb)
        checkTestModel(dom, 4, ma)

        mc = new TestModel( name: 'mc', x: 0, y: 1 )
        l.add(mc, 2)
        dom.contents().length.should.equal(11)
        checkTestModel(dom, 1, mb)
        checkTestModel(dom, 4, mc)
        checkTestModel(dom, 7, ma)

      it 'should correctly remove elements', ->
        l = new List([ 1, 2, 3, 4, 5 ])
        dom = (new ListView(l, { app: testApp })).artifact()

        l.remove(3)
        dom.children().length.should.equal(4)
        for label, idx in [ 1, 2, 4, 5 ]
          checkLiteral(dom.children().eq(idx), label)

      it 'should correctly remove multi-root subviews', ->
        ma = new TestModel( name: 'ma' )
        mb = new TestModel( name: 'mb', x: 0 )
        mc = new TestModel( name: 'mc', x: 0, y: 1 )
        l = new List([ 1, ma, mb, mc, 2 ])
        dom = (new ListView(l, { app: testApp })).artifact()

        l.remove(mb)
        dom.contents().length.should.equal(8)
        checkLiteral(dom.contents().eq(0), 1)
        checkTestModel(dom, 1, ma)
        checkTestModel(dom, 4, mc)
        checkLiteral(dom.contents().eq(7), 2)

        l.remove(ma)
        dom.contents().length.should.equal(5)
        checkLiteral(dom.contents().eq(0), 1)
        checkTestModel(dom, 1, mc)
        checkLiteral(dom.contents().eq(4), 2)

        l.remove(1)
        dom.contents().length.should.equal(4)
        checkTestModel(dom, 0, mc)
        checkLiteral(dom.contents().eq(3), 2)

      it 'should destroy views related to removed elements', ->
        l = new List([ 1, 2, 3, 4, 5 ])
        view = new ListView(l, { app: testApp })
        dom = view.artifact()
        view.wireEvents()

        destroyed = false
        victimView = dom.children().eq(2).data('view')
        victimView.on('destroying', -> destroyed = true)

        l.remove(3)
        destroyed.should.equal(true)

      it 'should unbind the render mutator related to removed elements', ->
        l = new List([ 1, 2, 3, 4, 5 ])
        view = new ListView(l, { app: testApp })
        dom = view.artifact()

        unbound = false
        victimMutator = view._mappedBindings.list[2]
        victimMutator.stop = -> unbound = true

        l.remove(3)
        unbound.should.equal(true)

    describe 'attaching', ->
      checkChild = (dom, idx, text) ->
        checkLiteral(dom.children().eq(idx), text)

      # we don't test every nook and cranny, only the things that differ from
      # the render path above. once set up, the two share a lot of machinery code.
      it 'should leave the initial dom be', ->
        l = new List([ 1, 2, 3 ])
        dom = $('<div><span class="janus-literal">one</span><span class="janus-literal">two</span><span class="janus-literal">three</span></div>')
        (new ListView(l, { app: testApp })).attach(dom)
        checkChild(dom, 0, 'one')
        checkChild(dom, 1, 'two')
        checkChild(dom, 2, 'three')

      it 'should update the correct nodes when they change', ->
        l = new List([ 1, 2, 3 ])
        dom = $('<div><span class="janus-literal">one</span><span class="janus-literal">two</span><span class="janus-literal">three</span></div>')
        (new ListView(l, { app: testApp })).attach(dom)

        l.removeAt(0)
        dom.children().length.should.equal(2)
        checkChild(dom, 0, 'two')
        checkChild(dom, 1, 'three')

        l.set(0, 4)
        dom.children().length.should.equal(2)
        checkChild(dom, 0, '4')
        checkChild(dom, 1, 'three')

        l.add(5)
        dom.children().length.should.equal(3)
        checkChild(dom, 0, '4')
        checkChild(dom, 1, 'three')
        checkChild(dom, 2, '5')

      it 'should update the correct nodes when they change', ->
        ma = new TestModel( name: 'ma' )
        l = new List([ 1, ma, 2 ])
        dom = $('<div><span class="janus-literal">one</span><div class="model-name">ma</div><div class="model-length">1</div> textnode <span class="janus-literal">two</span></div>')
        (new ListView(l, { app: testApp })).attach(dom)

        mb = new TestModel( name: 'mb', x: 0 )
        l.add(mb, 2)
        dom.contents().length.should.equal(8)
        checkLiteral(dom.contents().eq(0), 'one')
        checkTestModel(dom, 1, ma)
        checkTestModel(dom, 4, mb)
        checkLiteral(dom.contents().eq(7), 'two')

        l.remove(ma)
        dom.contents().length.should.equal(5)
        checkLiteral(dom.contents().eq(0), 'one')
        checkTestModel(dom, 1, mb)
        checkLiteral(dom.contents().eq(4), 'two')

        l.remove(1)
        dom.contents().length.should.equal(4)
        checkTestModel(dom, 0, mb)
        checkLiteral(dom.contents().eq(3), 'two')

    describe 'subview enumeration', ->
      describe 'subviews', ->
        it 'should return an empty list if there is no artifact', ->
          view = (new ListView(new List([ 1, 2, 3 ]), { app: testApp }))
          result = view.subviews()
          result.length_.should.equal(0)

        it 'should return a list of subviews', ->
          view = (new ListView(new List([ 1, 2, 3 ]), { app: testApp }))
          view.artifact()
          result = view.subviews()
          result.length_.should.equal(3)

          result.at_(0).subject.should.equal(1)
          result.at_(1).subject.should.equal(2)
          result.at_(2).subject.should.equal(3)

        it 'should update the subview list', ->
          list = new List([ 1, 2, 3 ])
          view = new ListView(list, { app: testApp })
          view.artifact()
          result = view.subviews()

          class A
          list.set(1, new A())
          list.add(4)

          result.length_.should.equal(3)
          result.at_(0).subject.should.equal(1)
          result.at_(1).subject.should.equal(3)
          result.at_(2).subject.should.equal(4)

      describe 'subviews_', ->
        it 'should return empty array if there is no artifact', ->
          (new ListView(new List([ 1, 2, 3 ]), { app: testApp }))
            .subviews_().should.eql([])

        it 'should return a list of subviews', ->
          view = (new ListView(new List([ 1, 2, 3 ]), { app: testApp }))
          view.artifact()
          view.subviews_().map((x) -> x.subject).should.eql([ 1, 2, 3 ])

        it 'should leave out nonrendered subviews', ->
          class A
          view = (new ListView(new List([ 1, new A, 3 ]), { app: testApp }))
          view.artifact()
          view.subviews_().map((x) -> x.subject).should.eql([ 1, 3 ])

    describe 'parent mutator interface', ->
      it 'should allow chaining on its render mutator', ->
        l = new List([ 1, 2, 3 ])
        renderItem = (render) -> render.context('test')

        library = new Library()
        library.register(Number, require('../../lib/view/literal').LiteralView, context: 'test')
        app = new App( views: library )

        dom = (new ListView(l, { app, renderItem })).artifact()

        dom.children().length.should.equal(3)
        for i in [0..2]
          checkLiteral(dom.children().eq(i), i + 1)

    describe 'events', ->
      it 'should wire events on extant children upon request', ->
        view = new ListView(new List([ 1, 2, 3 ]), { app: testApp })
        dom = view.artifact()
        view.wireEvents()

        dom.children().eq(0).data('view')._wired.should.equal(true)
        dom.children().eq(1).data('view')._wired.should.equal(true)
        dom.children().eq(2).data('view')._wired.should.equal(true)

      it 'should wire events on new children when added', ->
        l = new List([ 1 ])
        view = new ListView(l, { app: testApp })
        dom = view.artifact()
        view.wireEvents()

        dom.children().eq(0).data('view')._wired.should.equal(true)
        l.add(2)
        dom.children().eq(1).data('view')._wired.should.equal(true)
        l.add(3)
        dom.children().eq(2).data('view')._wired.should.equal(true)

      it 'should destroy all child views when destroyed', ->
        l = new List([ 1, 2, 3 ])
        view = new ListView(l, { app: testApp })
        dom = view.artifact()
        view.wireEvents() # we do this just so we have easy access to the subviews via .data('view'):

        subviews = dom.children().map(-> $(this).data('view')).toArray()
        destroyed = 0
        (subview._destroy = -> destroyed += 1) for subview in subviews

        view.destroy()
        destroyed.should.equal(3)

  describe 'set', ->
    # this is all really just a plumbing check; the SetView renders entirely
    # using the captive List within the Set, which is canonical.
    it 'should render with the internal set list', ->
      dom = (new SetView(new Set([ 1, 2, 3 ]), { app: testApp })).artifact()
      dom.children().length.should.equal(3)

      for i in [0..2]
        checkLiteral(dom.children().eq(i), i + 1)

