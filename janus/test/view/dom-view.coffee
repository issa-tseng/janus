should = require('should')

{ extend } = require('../../lib/util/util')
from = require('../../lib/core/from')
{ template, find } = require('../../lib/view/template')
{ DomView } = require('../../lib/view/dom-view')
{ Varying } = require('../../lib/core/varying')
{ Model } = require('../../lib/model/model')
{ List } = require('../../lib/collection/list')
$ = require('jquery')(require('domino').createWindow())

mockfrom = (v) -> { all: { point: -> Varying.of(v) } }
inf = -> inf

describe 'DomView', ->
  describe 'template dom handling', ->
    it 'renders based on the provided dom fragment method', ->
      TestView = DomView.build($('<div class="test"></div>'), inf)
      (new TestView()).artifact().is('.test').should.equal(true)

    it 'finds the appropriate spots in the dom', ->
      TestView = DomView.build($('<div><div class="title"></div><div class="body"></div></div>'),
        template(
          find('.title').text(mockfrom('mytitle'))
          find('.body').text(mockfrom('mybody'))
        ))

      artifact = (new TestView({})).artifact()
      artifact.find('.title').text().should.equal('mytitle')
      artifact.find('.body').text().should.equal('mybody')

  describe 'fragment attachment', ->
    it 'should trust the existing content', ->
      html = '<div><div class="title">title!</div><div class="body">body!</div></div>'
      TestView = DomView.build($(html), template(
        find('.title').text(mockfrom('mytitle'))
        find('.body').text(mockfrom('mybody'))
      ))

      fragment = $(html)
      (new TestView({})).attach(fragment)
      fragment.find('.title').text().should.equal('title!')
      fragment.find('.body').text().should.equal('body!')

    it 'should still update the existing content when it changes', ->
      html = '<div><div class="title">title!</div><div class="body">body!</div></div>'
      v = new Varying('mytitle')
      TestView = DomView.build($(html), template(
        find('.title').text(mockfrom(v))
        find('.body').text(mockfrom('mybody'))
      ))

      fragment = $(html)
      (new TestView({})).attach(fragment)
      fragment.find('.title').text().should.equal('title!')
      v.set('test title')
      fragment.find('.title').text().should.equal('test title')

    it 'should also attach child fragments', ->
      html = '<div><div class="child"><div class="title">title!</div></div></div>'
      v = new Varying('test title')
      TestOuter = DomView.build($(html), template(
        find('.child').render(mockfrom(new Model()))
      ))
      TestInner = DomView.build($('<div class="title"></div>'), template(
        find('.title').text(mockfrom(v))
      ))
      app = { view: (-> new TestInner({})) }

      fragment = $(html)
      (new TestOuter({}, { app })).attach(fragment)
      fragment.find('.title').length.should.equal(1)
      fragment.find('.title').text().should.equal('title!')

      v.set('changed title')
      fragment.find('.title').text().should.equal('changed title')

    it 'should wire attached views', ->
      wired = []
      html = '<div><div class="child"><div class="title">title!</div></div></div>'
      v = new Varying('test title')
      class TestOuter extends DomView.build($(html), template(
          find('.child').render(mockfrom(new Model()))
        ))
        _wireEvents: -> wired.push('outer')
      class TestInner extends DomView.build($('<div class="title"></div>'), template(
          find('.title').text(mockfrom(v))
        ))
        _wireEvents: -> wired.push('inner')
      app = { view: (-> new TestInner({})) }

      fragment = $(html)
      view = new TestOuter({}, { app })
      view.attach(fragment)

      wired.should.eql([])
      view.wireEvents()
      wired.should.eql([ 'outer', 'inner' ])

  describe 'template pointing', ->
    it 'applies a point function correctly', ->
      called = false
      TestView = class extends DomView.build($('<div></div>'),
        template(
          find('.title').text(from(->))
        ))
        pointer: -> -> called = true

      (new TestView({})).artifact()
      called.should.equal(true)

    it 'points dynamic function inputs correctly', ->
      passed = null
      v = new Varying('test')
      subject = {}
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from((x) -> passed = x; v))
      ))

      artifact = (new TestView(subject)).artifact()
      passed.should.equal(subject)
      artifact.text().should.equal('test')

      v.set('test 2')
      artifact.text().should.equal('test 2')

    it 'points dynamic string inputs correctly', ->
      attr = null
      v = new Varying('test')
      subject = { get: (x) -> attr = x; v }
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from('someattr'))
      ))

      artifact = (new TestView(subject)).artifact()
      attr.should.equal('someattr')
      artifact.text().should.equal('test')

      v.set('test 2')
      artifact.text().should.equal('test 2')

    it 'points dynamic other inputs correctly', ->
      v = new Varying('test')
      subject = { get: (x) -> attr = x; v }
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from(42))
      ))

      (new TestView(subject)).artifact().text().should.equal('42')

    it 'points get inputs correctly', ->
      attr = null
      v = new Varying('test')
      subject = { get: (x) -> attr = x; v }
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from.get('someattr'))
      ))

      artifact = (new TestView(subject)).artifact()
      attr.should.equal('someattr')
      artifact.text().should.equal('test')

      v.set('test 2')
      artifact.text().should.equal('test 2')

    it 'does not try to resolve literal subjects', ->
      attr = null
      rendered = []
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from('whatever'))
      ))

      artifact = (new TestView('hello')).artifact() # not crashing is also a check here.
      artifact.text().should.equal('whatever')

    it 'should get the subject given no parameter', ->
      attr = null
      rendered = []
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from.subject())
      ))

      artifact = (new TestView('hello')).artifact()
      artifact.text().should.equal('hello')

    it 'should get from the subject given a parameter', ->
      attr = null
      rendered = []
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from.subject('x'))
      ))

      artifact = (new TestView(new Model({ x: 42 }))).artifact()
      artifact.text().should.equal('42')

    it 'points attribute inputs correctly', ->
      attr = null
      subject = { attribute: (x) -> attr = x; 'test' }
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from.attribute('test_attr'))
      ))

      artifact = (new TestView(subject)).artifact()
      attr.should.equal('test_attr')
      artifact.text().should.equal('test')

    it 'should point at the viewmodel given no parameter', ->
      class ViewModel
        destroyWith: ->
        toString: -> 'view model instance'
      attr = null
      rendered = []
      TestView = DomView.build(ViewModel, $('<div></div>'), template(
        find('div').text(from.vm())
      ))

      artifact = (new TestView()).artifact()
      artifact.text().should.equal('view model instance')

    it 'should point at viewmodel data given a parameter', ->
      class ViewModel extends Model
        _initialize: -> this.set('test', 'vm test')

      attr = null
      rendered = []
      TestView = DomView.build(ViewModel, $('<div></div>'), template(
        find('div').text(from.vm('test'))
      ))

      artifact = (new TestView()).artifact()
      artifact.text().should.equal('vm test')

    it 'points varying function inputs correctly', ->
      passed = null
      v = new Varying('test')
      subject = {}
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from.varying((x) -> passed = x; v))
      ))

      artifact = (new TestView(subject)).artifact()
      passed.should.equal(subject)
      artifact.text().should.equal('test')

      v.set('test 2')
      artifact.text().should.equal('test 2')

    it 'points varying static inputs correctly', ->
      v = new Varying('test')
      subject = {}
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from.varying(v))
      ))

      artifact = (new TestView(subject)).artifact()
      artifact.text().should.equal('test')

      v.set('test 2')
      artifact.text().should.equal('test 2')

    it 'points app correctly', ->
      app = { toString: (-> 'test app'), on: (->) }
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from.app().map((x) -> x.toString()))
      ))

      artifact = (new TestView({}, { app })).artifact()
      artifact.text().should.equal('test app')

    it 'points app with a key reference correctly', ->
      rendered = watchedWith = null
      app = { toString: (-> 'test app'), on: (->), get: (key) -> watchedWith = key; new Varying('watched!') }
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from.app('testkey').map((x) -> x.toString()))
      ))

      artifact = (new TestView({}, { app })).artifact()
      artifact.text().should.equal('watched!')
      watchedWith.should.equal('testkey')

    it 'points self functions correctly', ->
      pointed = null
      v = new Varying('test')
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from.self((x) -> pointed = x; v))
      ))

      t = new TestView({})
      artifact = t.artifact()
      pointed.should.equal(t)
      artifact.text().should.equal('test')

      v.set('test 2')
      artifact.text().should.equal('test 2')

    it 'points static self correctly', ->
      pointed = null
      v = new Varying('test')
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from.self().flatMap((x) -> pointed = x; v))
      ))

      t = new TestView({})
      artifact = t.artifact()
      pointed.should.equal(t)
      artifact.text().should.equal('test')

      v.set('test 2')
      artifact.text().should.equal('test 2')

  describe 'subview enumeration', ->
    describe 'subviews_', ->
      it 'should return empty array if the view has not yet rendered', ->
        TestOuter = DomView.build($('<div><div class="child"></div></div>'), template(
          find('.child').render(mockfrom(new Model()))
        ))
        TestInner = DomView.build($('<div class="inner"></div>'), template())
        app = { view: (-> new TestInner({})) }

        view = new TestOuter({}, { app })
        view.subviews_().length.should.equal(0)

      it 'should return views that have been rendered', ->
        TestOuter = DomView.build($('<div><div class="child"></div></div>'), template(
          find('.child').render(mockfrom(new Model()))
        ))
        TestInner = DomView.build($('<div class="inner"></div>'), template())
        app = { view: (-> new TestInner({})) }

        view = new TestOuter({}, { app })
        view.artifact()
        view.subviews_().length.should.equal(1)
        view.subviews_()[0].should.be.an.instanceof(TestInner)

      it 'should not include views that did not actually render', ->
        TestOuter = DomView.build($('<div><div class="child"></div></div>'), template(
          find('.child').render(mockfrom(new Model()))
        ))
        app = { view: (->) }

        view = new TestOuter({}, { app })
        view.artifact()
        view.subviews_().length.should.equal(0)

    describe 'subviews', ->
      it 'should return empty list if the view has not yet rendered', ->
        TestOuter = DomView.build($('<div><div class="child"></div></div>'), template(
          find('.child').render(mockfrom(new Model()))
        ))
        TestInner = DomView.build($('<div class="inner"></div>'), template())
        app = { view: (-> new TestInner({})) }

        view = new TestOuter({}, { app })
        view.subviews().length_.should.equal(0)

      it 'should return and maintain a list of subviews', ->
        v = new Varying('test')
        viewer = -> new TestInner({})
        TestOuter = DomView.build($('<div><div class="child"></div></div>'), template(
          find('.child').render(mockfrom(v))
        ))
        TestInner = DomView.build($('<div class="inner"></div>'), template())
        app = { view: (-> viewer()) }

        view = new TestOuter({}, { app })
        view.artifact()
        result = view.subviews()

        result.length_.should.equal(1)
        first = result.get_(0)
        first.should.be.an.instanceof(TestInner)

        v.set('test2')
        result.length_.should.equal(1)
        result.get_(0).should.be.an.instanceof(TestInner)
        result.get_(0).should.not.equal(first)

        viewer = ->
        v.set('test3')
        result.length_.should.equal(0)

      it 'should give rendered subviews once the view has rendered', ->
        v = new Varying('test')
        viewer = -> new TestInner({})
        TestOuter = DomView.build($('<div><div class="child"></div></div>'), template(
          find('.child').render(mockfrom(v))
        ))
        TestInner = DomView.build($('<div class="inner"></div>'), template())
        app = { view: (-> viewer()) }

        view = new TestOuter({}, { app })
        result = view.subviews()
        result.length_.should.equal(0)

        view.artifact()
        result.length_.should.equal(1)
        first = result.get_(0)
        first.should.be.an.instanceof(TestInner)

  describe 'client event wiring', ->
    it 'should call _wireEvents', ->
      called = false
      TestView = class extends DomView.build($('<div></div>'), inf)
        _wireEvents: -> called = true

      (new TestView()).wireEvents()
      called.should.equal(true)

    it 'only wires events once', ->
      count = 0
      TestView = class extends DomView.build($('<div></div>'), inf)
        _wireEvents: -> count += 1

      view = new TestView({})
      view.wireEvents()
      view.wireEvents()
      count.should.equal(1)

    it 'adds a reference to self on the top-level dom node', ->
      TestView = DomView.build($('<div></div>'), inf)

      view = new TestView()
      view.wireEvents()
      view.artifact().data('view').should.equal(view)

    it 'also wires subview events', ->
      wired = []
      ParentView = class extends DomView.build($('<div><div class="a"></div><div class="b"></div></div>'), template(
          find('.a').render(from(true))
          find('.b').render(from(true))
        ))
        _wireEvents: -> wired.push(this)
      ChildView = class extends DomView.build($('<div></div>'), inf)
        _wireEvents: -> wired.push(this)
      app = { view: -> new ChildView() }

      view = new ParentView({}, { app })
      wired.length.should.equal(0)
      view.wireEvents()
      wired.length.should.equal(3)
      wired[0].should.equal(view)
      wired[1].should.be.an.instanceof(ChildView)
      wired[2].should.be.an.instanceof(ChildView)

    it 'wires subview events as new subviews are rendered', ->
      wired = []
      v = new Varying(0)
      ParentView = class extends DomView.build($('<div></div>'), template(
          find('div').render(from(v))
        ))
        _wireEvents: -> wired.push(this)
      ChildView = class extends DomView.build($('<div></div>'), inf)
        _wireEvents: -> wired.push(this)
      app = { view: -> new ChildView() }

      view = new ParentView({}, { app })
      view.wireEvents()
      wired.length.should.equal(2)

      v.set(1)
      wired.length.should.equal(3)
      wired[2].should.be.an.instanceof(ChildView)

    it 'runs template .on declarations', ->
      called = []
      TestView = DomView.build($('<div></div>'), template(
        find('div')
          .on('click', (event) -> called.push(event.type))
          .on('mouseover', (event) -> called.push(event.type))))
      view = new TestView({})
      dom = view.artifact()
      dom.trigger('click')
      called.should.eql([])
      view.wireEvents()
      dom.trigger('mouseover')
      dom.trigger('click')
      called.should.eql([ 'mouseover', 'click' ])

    it 'stops template .on declarations on destroy', ->
      called = []
      TestView = DomView.build($('<div></div>'), template(
        find('div')
          .on('click', (event) -> called.push(event.type))
          .on('mouseover', (event) -> called.push(event.type))))
      view = new TestView({})
      dom = view.artifact()
      view.wireEvents()
      dom.trigger('mouseover')
      view.destroy()
      dom.trigger('click')
      dom.trigger('mouseover')
      called.should.eql([ 'mouseover' ])

  it 'concats dom outerHTMLs to provide markup', ->
    TestView = DomView.build($('<div><div>123</div><div>abc</div></div>'), inf)
    (new TestView()).markup().should.equal('<div><div>123</div><div>abc</div></div>')

  describe 'lifecycle', ->
    it 'will never produce an artifact if destroyed prior', ->
      TestView = DomView.build($('<div></div>'), inf)
      view = new TestView()
      view.destroy()
      should.not.exist(view.artifact().html)

    it 'triggers a `destroying` event on the dom fragment root', ->
      evented = false
      TestView = DomView.build($('<div></div>'), inf)
      view = new TestView()
      view.artifact().on('destroying', -> evented = true)

      evented.should.equal(false)
      view.destroy()
      evented.should.equal(true)

    it 'removes itself from the dom when destroyed', ->
      TestView = DomView.build($('<div></div>'), inf)
      view = new TestView()

      parent = $('<div></div>')
      parent.append(view.artifact())
      parent.children().length.should.equal(1)

      view.destroy()
      parent.children().length.should.equal(0)

    it 'stops all related bindings when destroyed', ->
      v = new Varying('test')
      TestView = DomView.build($('<div></div>'), template(
        find('div').text(from(v))
      ))

      view = new TestView({})
      artifact = view.artifact()
      artifact.text().should.equal('test')

      v.set('test 2')
      artifact.text().should.equal('test 2')

      view.destroy()
      v.set('test 3')
      artifact.text().should.equal('test 2')

    # it is the render mutator's job to destroy children when it rotates in a new
    # view in place of an old one, so we don't test that here. we only test that
    # destroying a view destroys all children at that moment.
    it 'destroys children when destroyed', ->
      destroyed = []
      ParentView = class extends DomView.build($('<div><div class="a"></div><div class="b"></div></div>'), template(
          find('.a').render(from(true))
          find('.b').render(from(true))
        ))
        destroy: -> destroyed.push(this); super()
      ChildView = class extends DomView.build($('<div></div>'), inf)
        destroy: -> destroyed.push(this); super()
      app = { view: -> new ChildView() }

      view = new ParentView({}, { app })
      view.artifact()
      destroyed.length.should.equal(0)

      view.destroy()
      destroyed.length.should.equal(3)

    # i don't really know how to test this without reaching into internals:
    it 'stops trying to wire new subview events when destroyed', ->
      ParentView = DomView.build($('<div><div class="a"></div><div class="b"></div></div>'), template(
        find('.a').render(from(true))
        find('.b').render(from(true))
      ))
      ChildView = DomView.build($('<div></div>'), inf)
      app = { view: -> new ChildView() }

      view = new ParentView({}, { app })
      view.wireEvents()

      view._subwires.length.should.equal(2)
      view.destroy()
      view._subwires[0].stopped.should.equal(true)
      view._subwires[1].stopped.should.equal(true)

  describe 'viewModel declaration', ->
    it 'should create a ViewModel if one is provided via builder options', ->
      class MyModel extends Model
        id: 'real mccoy'
      class MyViewModel extends Model
        id: 'just a viewmodel'

      WithViewModel = DomView.build(
        MyViewModel,
        $('<div></div>'),
        find('div').text(from.self((view) -> view.viewModel.id))
      )

      model = new MyModel()
      view = new WithViewModel(model)
      view.artifact().text().should.equal('just a viewmodel')

