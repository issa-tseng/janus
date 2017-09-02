should = require('should')

{ extend } = require('../../lib/util/util')
from = require('../../lib/core/from')
{ template, find } = require('../../lib/view/template')
{ DomView } = require('../../lib/view/dom-view')
{ Varying } = require('../../lib/core/varying')
{ List } = require('../../lib/collection/list')

inf = -> inf
makeDom = (dom = {}) ->
  result = { remove: (->), append: (->), find: (-> result), data: (->), prepend: (-> result), children: (-> result) }
  extend(result, dom)
  result

describe 'DomView', ->
  describe 'definition', ->
    it 'throws an exception if no dom method is provided', ->
      class TestView extends DomView
        @_template: -> inf

      view = new TestView({})
      thrown = null
      try
        view.artifact()
      catch ex
        thrown = ex.message
      thrown.should.equal('no dom fragment provided!')

    it 'throws an exception if no template method is provided', ->
      class TestView extends DomView
        @_dom: -> makeDom()

      view = new TestView({})
      thrown = null
      try
        view.artifact()
      catch ex
        thrown = ex.message
      thrown.should.equal('no template provided!')

  describe 'template dom handling', ->
    it 'renders based on the provided dom fragment method', ->
      dom = makeDom()
      class TestView extends DomView
        @_dom: -> dom
        @_template: inf

      (new TestView()).artifact().should.equal(dom)

    it 'uses the existing parent if there is one', ->
      calledParentFind = false
      parent = { find: (calledParentFind = true; -> parent), text: (->), length: 1 }
      dom = { find: (-> dom), data: (->), parent: (-> parent) }
      class TestView extends DomView
        @_dom: -> dom
        @_template: template(find('.heading').text(from('test')))

      (new TestView({ resolve: -> })).artifact().should.equal(dom)
      calledParentFind.should.equal(true)

    it 'finds the appropriate spots in the dom', ->
      finds = []
      dom = makeDom({ find: ((x) -> finds.push(x); dom), text: (->) })

      class TestView extends DomView
        @_dom: -> dom
        @_template: template(
          find('.title').text(from('somewhere'))
          find('.body').text(from('somewhere-else'))
        )

      (new TestView({ resolve: -> })).artifact()
      finds.should.eql([ '.title', '.body' ])

  describe 'template pointing', ->
    it 'applies a point function correctly', ->
      called = false
      class TestView extends DomView
        @_dom: -> makeDom({ text: (->) })
        @_template: template(
          find('.title').text(from((x) -> passed = x; v))
        )
        @_point: -> called = true

      (new TestView({})).artifact()
      called.should.equal(true)

    it 'points dynamic function inputs correctly', ->
      passed = null
      rendered = []
      v = new Varying('test')

      subject = {}

      class TestView extends DomView
        @_dom: -> makeDom({ text: ((x) -> rendered.push(x)) })
        @_template: template(
          find('.title').text(from((x) -> passed = x; v))
        )

      (new TestView(subject)).artifact()
      passed.should.equal(subject)
      rendered.should.eql([ 'test' ])

      v.set('test 2')
      rendered.should.eql([ 'test', 'test 2' ])

    it 'points dynamic string inputs correctly', ->
      attr = null
      rendered = []

      v = new Varying('test')
      subject = { resolve: (x) -> attr = x; v }

      class TestView extends DomView
        @_dom: -> makeDom({ text: ((x) -> rendered.push(x)) })
        @_template: template(find('.title').text(from('someattr')))

      (new TestView(subject)).artifact()
      rendered.should.eql([ 'test' ])

      v.set('test 2')
      rendered.should.eql([ 'test', 'test 2' ])

    it 'points dynamic other inputs correctly', ->
      rendered = []

      v = new Varying('test')
      subject = { resolve: (x) -> attr = x; v }

      class TestView extends DomView
        @_dom: -> makeDom({ text: ((x) -> rendered.push(x)) })
        @_template: template(find('.title').text(from(42)))

      (new TestView(subject)).artifact()
      rendered.should.eql([ '42' ])

    it 'points watch inputs correctly', ->
      attr = null
      rendered = []

      v = new Varying('test')
      subject = { watch: (x) -> attr = x; v }

      class TestView extends DomView
        @_dom: -> makeDom({ text: ((x) -> rendered.push(x)) })
        @_template: template(find('.title').text(from.watch('someattr')))

      (new TestView(subject)).artifact()
      attr.should.equal('someattr')
      rendered.should.eql([ 'test' ])

      v.set('test 2')
      rendered.should.eql([ 'test', 'test 2' ])

    it 'points resolve inputs correctly', ->
      attr = null
      rendered = []

      v = new Varying('test')
      subject = { resolve: (x) -> attr = x; v }

      class TestView extends DomView
        @_dom: -> makeDom({ text: ((x) -> rendered.push(x)) })
        @_template: template(find('.title').text(from.resolve('someattr')))

      (new TestView(subject)).artifact()
      attr.should.equal('someattr')
      rendered.should.eql([ 'test' ])

      v.set('test 2')
      rendered.should.eql([ 'test', 'test 2' ])

    it 'does not try to resolve literal subjects', ->
      attr = null
      rendered = []

      class TestView extends DomView
        @_dom: -> makeDom({ text: ((x) -> rendered.push(x)) })
        @_template: template(find('.title').text(from('whatever')))

      (new TestView('hello')).artifact()
      rendered.should.eql([ 'whatever' ])
      # not crashing is also a check here.

    it 'points attribute inputs correctly', ->
      attr = null
      rendered = []

      attribute = 'test'
      subject = { attribute: (x) -> attr = x; attribute }

      class TestView extends DomView
        @_dom: -> makeDom({ text: ((x) -> rendered.push(x)) })
        @_template: template(find('.title').text(from.attribute('test_attr')))

      (new TestView(subject)).artifact()
      attr.should.equal('test_attr')
      rendered.should.eql([ 'test' ])

    it 'points varying function inputs correctly', ->
      passed = null
      rendered = []
      v = new Varying('test')

      subject = {}

      class TestView extends DomView
        @_dom: -> makeDom({ text: ((x) -> rendered.push(x)) })
        @_template: template(
          find('.title').text(from.varying((x) -> passed = x; v))
        )

      (new TestView(subject)).artifact()
      passed.should.equal(subject)
      rendered.should.eql([ 'test' ])

      v.set('test 2')
      rendered.should.eql([ 'test', 'test 2' ])

    it 'points varying static inputs correctly', ->
      rendered = []
      v = new Varying('test')

      subject = {}

      class TestView extends DomView
        @_dom: -> makeDom({ text: ((x) -> rendered.push(x)) })
        @_template: template(
          find('.title').text(from.varying(v))
        )

      (new TestView(subject)).artifact()
      rendered.should.eql([ 'test' ])

      v.set('test 2')
      rendered.should.eql([ 'test', 'test 2' ])

    it 'points app correctly', ->
      rendered = null
      app = { toString: (-> 'test app'), on: (->) }
      class TestView extends DomView
        @_dom: -> makeDom({ text: ((x) -> rendered = x) })
        @_template: template(find('.title').text(from.app().map((x) -> x.toString())))

      (new TestView({}, { app })).artifact()
      rendered.should.equal('test app')

    it 'points app with a key reference correctly', ->
      rendered = resolvedWith = null
      app = { toString: (-> 'test app'), on: (->), resolve: (key) -> resolvedWith = key; new Varying('resolved!') }
      class TestView extends DomView
        @_dom: -> makeDom({ text: ((x) -> rendered = x) })
        @_template: template(find('.title').text(from.app('testkey').map((x) -> x.toString())))

      (new TestView({}, { app })).artifact()
      rendered.should.equal('resolved!')
      resolvedWith.should.equal('testkey')

    it 'points self functions correctly', ->
      rendered = []
      pointed = null
      v = new Varying('test')

      class TestView extends DomView
        @_dom: -> makeDom({ text: ((x) -> rendered.push(x)) })
        @_template: template(
          find('.title').text(from.self((x) -> pointed = x; v))
        )

      t = new TestView({})
      t.artifact()
      pointed.should.equal(t)
      rendered.should.eql([ 'test' ])

      v.set('test 2')
      rendered.should.eql([ 'test', 'test 2' ])

    it 'points static self correctly', ->
      rendered = []
      pointed = null
      v = new Varying('test')

      class TestView extends DomView
        @_dom: -> makeDom({ text: ((x) -> rendered.push(x)) })
        @_template: template(
          find('.title').text(from.self().flatMap((x) -> pointed = x; v))
        )

      t = new TestView({})
      t.artifact()
      pointed.should.equal(t)
      rendered.should.eql([ 'test' ])

      v.set('test 2')
      rendered.should.eql([ 'test', 'test 2' ])

  describe 'dom events', ->
    it 'emits appendedToDocument when it is appended to body', ->
      class TestView extends DomView
        @_dom: -> makeDom({ text: (->), closest: (-> [ 42 ]) })
        @_template: template(find('.title').text(from.varying(42)))

      emitted = false
      view = new TestView({})
      view.on('appendedToDocument', -> emitted = true)
      view.artifact()
      emitted.should.equal(false)
      view.emit('appended')
      emitted.should.equal(true)

    it 'emits appendedToDocument only when it is appended to body', ->
      class TestView extends DomView
        @_dom: -> makeDom ({ text: (->), closest: (-> []) })
        @_template: template(find('.title').text(from.varying(42)))

      emitted = false
      view = new TestView({})
      view.on('appendedToDocument', -> emitted = true)
      view.artifact()
      view.emit('appended')
      emitted.should.equal(false)

    it 'triggers appended events on subviews when appended to body', ->
      class TestView extends DomView
        @_dom: -> makeDom({ text: (->), closest: (-> [ 42 ]) })
        @_template: template(find('.title').text(from.varying(42)))

      called = 0
      childA = new TestView({})
      childA.on('appended', -> called += 1)
      childB = new TestView({})
      childB.on('appended', -> called += 1)
      subviews = new List([ childA, childB ])

      view = new TestView({})
      view._subviews = subviews # yeah, i know, i'm cheating.
      view.artifact()
      called.should.equal(0)
      view.emit('appended')
      called.should.equal(2)

  describe 'client event wiring', ->
    it 'only wires events once', ->
      count = 0
      class TestView extends DomView
        @_dom: -> makeDom()
        @_template: inf
        _wireEvents: -> count += 1

      view = new TestView({})
      view.wireEvents()
      view.wireEvents()
      count.should.equal(1)

    it 'adds a reference to self on the top-level dom node', ->
      dataKey = dataValue = null
      class TestView extends DomView
        @_dom: -> makeDom({ data: ((k, v) -> dataKey = k; dataValue = v) })
        @_template: inf

      view = new TestView()
      view.wireEvents()
      dataKey.should.equal('view')
      dataValue.should.equal(view)

    it 'also wires subview events', ->
      wired = []
      class TestView extends DomView
        @_dom: -> makeDom({ data: ((k, v) -> dataKey = k; dataValue = v) })
        @_template: inf
        _wireEvents: -> wired.push(this)

      childA = new TestView({})
      childB = new TestView({})
      subviews = new List([ childA, childB ])

      view = new TestView()
      view._subviews = subviews
      view.wireEvents()
      wired.should.eql([ view, childA, childB ])

    it 'wires child events if appropriate', ->
      wired = 0
      class TestView extends DomView
        @_dom: -> makeDom()
        @_template: inf
        _wireEvents: -> wired += 1

      child = new TestView()
      app = { on: ((event, f_) -> this.f_ = f_ if event is 'vended'), vendView: -> this.f_('views', child); child }
      parent = new TestView({}, { app })

      parent.wireEvents()
      app.vendView()
      wired.should.equal(2)

    it 'defers wiring child events until appropriate', ->
      wired = 0
      class TestView extends DomView
        @_dom: -> makeDom()
        @_template: inf
        _wireEvents: -> wired += 1

      child = new TestView()
      app = { on: ((event, f_) -> this.f_ = f_ if event is 'vended'), vendView: -> this.f_('views', child); child }
      parent = new TestView({}, { app })

      app.vendView()
      wired.should.equal(0)

      parent.wireEvents()
      wired.should.equal(2)

  it 'concats dom outerHTMLs to provide markup', ->
    class TestView extends DomView
      @_dom: -> makeDom({ get: (-> [ { outerHTML: '123' }, { outerHTML: 'abc' } ]) })
      @_template: inf

    view = new TestView()
    view.markup().should.equal('123abc')

  describe 'lifecycle', ->
    it 'triggers a `destroying` event on the dom fragment root', ->
      triggered = null

      class TestView extends DomView
        @_dom: -> makeDom({ trigger: ((x) -> triggered = x), text: (->) })
        @_template: template(
          find('.title').text(from(42))
        )

      view = new TestView({})
      view.artifact()

      should(triggered).equal(null)
      view.destroy()
      triggered.should.equal('destroying')

    it 'removes itself from the dom when destroyed', ->
      removed = false

      class TestView extends DomView
        @_dom: -> makeDom({ remove: (-> removed = true), children: (-> makeDom({ text: (->) })) })
        @_template: template(
          find('.title').text(from(42))
        )

      view = new TestView({})
      view.artifact()

      removed.should.equal(false)
      view.destroy()
      removed.should.equal(true)

    it 'stops all related bindings when destroyed', ->
      rendered = []
      v = new Varying('test')

      class TestView extends DomView
        @_dom: -> makeDom({ text: ((x) -> rendered.push(x)) })
        @_template: template(
          find('.title').text(from(v))
        )

      view = new TestView({})
      view.artifact()
      rendered.should.eql([ 'test' ])

      v.set('test 2')
      rendered.should.eql([ 'test', 'test 2' ])

      view.destroy()
      v.set('test 3')
      rendered.should.eql([ 'test', 'test 2' ])

