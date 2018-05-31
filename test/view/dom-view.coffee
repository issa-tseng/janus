should = require('should')

{ extend } = require('../../lib/util/util')
from = require('../../lib/core/from')
{ template, find } = require('../../lib/view/template')
{ DomView } = require('../../lib/view/dom-view')
{ Varying } = require('../../lib/core/varying')
{ Model } = require('../../lib/model/model')
{ List } = require('../../lib/collection/list')
$ = require('jquery')(require('domino').createWindow())

mockfrom = (v) -> { all: { point: -> Varying.ly(v) } }
inf = -> inf

describe 'DomView', ->
  describe 'template dom handling', ->
    it 'renders based on the provided dom fragment method', ->
      TestView = DomView.build($('<div class="test"/>'), inf)
      (new TestView()).artifact().is('.test').should.equal(true)

    it 'finds the appropriate spots in the dom', ->
      TestView = DomView.build($('<div><div class="title"/><div class="body"/></div>'),
        template(
          find('.title').text(mockfrom('mytitle'))
          find('.body').text(mockfrom('mybody'))
        ))

      artifact = (new TestView({})).artifact()
      artifact.find('.title').text().should.equal('mytitle')
      artifact.find('.body').text().should.equal('mybody')

  describe 'template pointing', ->
    it 'applies a point function correctly', ->
      called = false
      TestView = class extends DomView.build($('<div/>'),
        template(
          find('.title').text(from((x) -> passed = x; v))
        ))
        @point: (-> called = true)

      (new TestView({})).artifact()
      called.should.equal(true)

    it 'points dynamic function inputs correctly', ->
      passed = null
      v = new Varying('test')
      subject = {}
      TestView = DomView.build($('<div/>'), template(
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
      subject = { resolve: (x) -> attr = x; v }
      TestView = DomView.build($('<div/>'), template(
        find('div').text(from('someattr'))
      ))

      artifact = (new TestView(subject)).artifact()
      attr.should.equal('someattr')
      artifact.text().should.equal('test')

      v.set('test 2')
      artifact.text().should.equal('test 2')

    it 'points dynamic other inputs correctly', ->
      v = new Varying('test')
      subject = { resolve: (x) -> attr = x; v }
      TestView = DomView.build($('<div/>'), template(
        find('div').text(from(42))
      ))

      (new TestView(subject)).artifact().text().should.equal('42')

    it 'points watch inputs correctly', ->
      attr = null
      v = new Varying('test')
      subject = { watch: (x) -> attr = x; v }
      TestView = DomView.build($('<div/>'), template(
        find('div').text(from.watch('someattr'))
      ))

      artifact = (new TestView(subject)).artifact()
      attr.should.equal('someattr')
      artifact.text().should.equal('test')

      v.set('test 2')
      artifact.text().should.equal('test 2')

    it 'points resolve inputs correctly', ->
      attr = null
      v = new Varying('test')
      subject = { resolve: (x) -> attr = x; v }
      TestView = DomView.build($('<div/>'), template(
        find('div').text(from.resolve('someattr'))
      ))

      artifact = (new TestView(subject)).artifact()
      attr.should.equal('someattr')
      artifact.text().should.equal('test')

      v.set('test 2')
      artifact.text().should.equal('test 2')

    it 'does not try to resolve literal subjects', ->
      attr = null
      rendered = []
      TestView = DomView.build($('<div/>'), template(
        find('div').text(from('whatever'))
      ))

      artifact = (new TestView('hello')).artifact() # not crashing is also a check here.
      artifact.text().should.equal('whatever')

    it 'points attribute inputs correctly', ->
      attr = null
      subject = { attribute: (x) -> attr = x; 'test' }
      TestView = DomView.build($('<div/>'), template(
        find('div').text(from.attribute('test_attr'))
      ))

      artifact = (new TestView(subject)).artifact()
      attr.should.equal('test_attr')
      artifact.text().should.equal('test')

    it 'points varying function inputs correctly', ->
      passed = null
      v = new Varying('test')
      subject = {}
      TestView = DomView.build($('<div/>'), template(
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
      TestView = DomView.build($('<div/>'), template(
        find('div').text(from.varying(v))
      ))

      artifact = (new TestView(subject)).artifact()
      artifact.text().should.equal('test')

      v.set('test 2')
      artifact.text().should.equal('test 2')

    it 'points app correctly', ->
      app = { toString: (-> 'test app'), on: (->) }
      TestView = DomView.build($('<div/>'), template(
        find('div').text(from.app().map((x) -> x.toString()))
      ))

      artifact = (new TestView({}, { app })).artifact()
      artifact.text().should.equal('test app')

    it 'points app with a key reference correctly', ->
      rendered = resolvedWith = null
      app = { toString: (-> 'test app'), on: (->), resolve: (key) -> resolvedWith = key; new Varying('resolved!') }
      TestView = DomView.build($('<div/>'), template(
        find('div').text(from.app('testkey').map((x) -> x.toString()))
      ))

      artifact = (new TestView({}, { app })).artifact()
      artifact.text().should.equal('resolved!')
      resolvedWith.should.equal('testkey')

    it 'points self functions correctly', ->
      pointed = null
      v = new Varying('test')
      TestView = DomView.build($('<div/>'), template(
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
      TestView = DomView.build($('<div/>'), template(
        find('div').text(from.self().flatMap((x) -> pointed = x; v))
      ))

      t = new TestView({})
      artifact = t.artifact()
      pointed.should.equal(t)
      artifact.text().should.equal('test')

      v.set('test 2')
      artifact.text().should.equal('test 2')

  describe 'client event wiring', ->
    it 'only wires events once', ->
      count = 0
      TestView = class extends DomView.build($('<div/>'), inf)
        _wireEvents: -> count += 1

      view = new TestView({})
      view.wireEvents()
      view.wireEvents()
      count.should.equal(1)

    it 'adds a reference to self on the top-level dom node', ->
      TestView = DomView.build($('<div/>'), inf)

      view = new TestView()
      view.wireEvents()
      view.artifact().data('view').should.equal(view)

    it 'also wires subview events', ->
      wired = []
      ParentView = class extends DomView.build($('<div><div class="a"/><div class="b"/></div>'), template(
          find('.a').render(from(true))
          find('.b').render(from(true))
        ))
        _wireEvents: -> wired.push(this)
      ChildView = class extends DomView.build($('<div/>'), inf)
        _wireEvents: -> wired.push(this)
      app = { vendView: -> new ChildView() }

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
      ParentView = class extends DomView.build($('<div/>'), template(
          find('div').render(from(v))
        ))
        _wireEvents: -> wired.push(this)
      ChildView = class extends DomView.build($('<div/>'), inf)
        _wireEvents: -> wired.push(this)
      app = { vendView: -> new ChildView() }

      view = new ParentView({}, { app })
      view.wireEvents()
      wired.length.should.equal(2)

      v.set(1)
      wired.length.should.equal(3)
      wired[2].should.be.an.instanceof(ChildView)

    it 'accepts a wireEvents via options, and gives it the appropriate parameters', ->
      called = false
      subject = {}
      TestView = DomView.build($('<div/>'), inf, {
        wireEvents: (partifact, psubject, pview) ->
          partifact.is('div').should.equal(true)
          psubject.should.equal(subject)
          pview.should.equal(view)
          called = true
      })
      view = new TestView(subject)
      view.wireEvents()
      called.should.equal(true)

    it 'runs template .on declarations', ->
      called = []
      TestView = DomView.build($('<div/>'), template(
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
      TestView = DomView.build($('<div/>'), template(
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
    it 'triggers a `destroying` event on the dom fragment root', ->
      evented = false
      TestView = DomView.build($('<div/>'), inf)
      view = new TestView()
      view.artifact().on('destroying', -> evented = true)

      evented.should.equal(false)
      view.destroy()
      evented.should.equal(true)

    it 'removes itself from the dom when destroyed', ->
      TestView = DomView.build($('<div/>'), inf)
      view = new TestView()

      parent = $('<div/>')
      parent.append(view.artifact())
      parent.children().length.should.equal(1)

      view.destroy()
      parent.children().length.should.equal(0)

    it 'stops all related bindings when destroyed', ->
      v = new Varying('test')
      TestView = DomView.build($('<div/>'), template(
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
      ParentView = class extends DomView.build($('<div><div class="a"/><div class="b"/></div>'), template(
          find('.a').render(from(true))
          find('.b').render(from(true))
        ))
        _destroy: -> destroyed.push(this); super()
      ChildView = class extends DomView.build($('<div/>'), inf)
        _destroy: -> destroyed.push(this); super()
      app = { vendView: -> new ChildView() }

      view = new ParentView({}, { app })
      view.artifact()
      destroyed.length.should.equal(0)

      view.destroy()
      destroyed.length.should.equal(3)

    # i don't really know how to test this without reaching into internals:
    it 'stops trying to wire new subview events when destroyed', ->
      ParentView = DomView.build($('<div><div class="a"/><div class="b"/></div>'), template(
        find('.a').render(from(true))
        find('.b').render(from(true))
      ))
      ChildView = DomView.build($('<div/>'), inf)
      app = { vendView: -> new ChildView() }

      view = new ParentView({}, { app })
      view.wireEvents()

      view._subwires.length.should.equal(2)
      view.destroy()
      view._subwires[0].stopped.should.equal(true)
      view._subwires[1].stopped.should.equal(true)

  describe 'viewModel declaration', ->
    it 'should wrap in ViewModel if one is provided via options', ->
      class MyModel extends Model
        id: 'real mccoy'
      class MyViewModel extends Model
        id: 'just a viewmodel'

      WithViewModel = DomView.build($('<div/>'), template(
        find('div').text(from.self((view) -> view.subject.id))
      ), { viewModelClass: MyViewModel })


      model = new MyModel()
      view = new WithViewModel(model)
      view.artifact().text().should.equal('just a viewmodel')

