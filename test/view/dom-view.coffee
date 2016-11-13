should = require('should')

from = require('../../lib/core/from')
{ template, find } = require('../../lib/view/template')
{ DomView } = require('../../lib/view/dom-view')
{ Varying } = require('../../lib/core/varying')
{ List } = require('../../lib/collection/collection')

inf = -> inf

describe 'dom-view', ->
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
        @_dom: -> {}

      view = new TestView({})
      thrown = null
      try
        view.artifact()
      catch ex
        thrown = ex.message
      thrown.should.equal('no template provided!')

  describe 'template dom handling', ->
    it 'renders based on the provided dom fragment method', ->
      dom = { find: -> dom }
      class TestView extends DomView
        @_dom: -> dom
        @_template: inf

      (new TestView()).artifact().should.equal(dom)

    it 'finds the appropriate spots in the dom', ->
      finds = []
      dom = { find: ((x) -> finds.push(x); dom), text: (->) }

      class TestView extends DomView
        @_dom: -> dom
        @_template: template(
          find('.title').text(from('somewhere'))
          find('.body').text(from('somewhere-else'))
        )

      (new TestView({ watch: -> })).artifact()
      finds.should.eql([ '.title', '.body' ])

  describe 'template pointing', ->
    it 'applies a point function correctly', ->
      called = false
      dom = { find: (-> dom), text: (->) }
      class TestView extends DomView
        @_dom: -> dom
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

      dom = { find: (-> dom), text: ((x) -> rendered.push(x)) }
      subject = {}

      class TestView extends DomView
        @_dom: -> dom
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
      dom = { find: (-> dom), text: ((x) -> rendered.push(x)) }
      subject = { watch: (x) -> attr = x; v }

      class TestView extends DomView
        @_dom: -> dom
        @_template: template(find('.title').text(from('someattr')))

      (new TestView(subject)).artifact()
      rendered.should.eql([ 'test' ])

      v.set('test 2')
      rendered.should.eql([ 'test', 'test 2' ])

    it 'points dynamic other inputs correctly', ->
      rendered = []

      v = new Varying('test')
      dom = { find: (-> dom), text: ((x) -> rendered.push(x)) }
      subject = { watch: (x) -> attr = x; v }

      class TestView extends DomView
        @_dom: -> dom
        @_template: template(find('.title').text(from(42)))

      (new TestView(subject)).artifact()
      rendered.should.eql([ '42' ])

    it 'points attr inputs correctly', ->
      attr = null
      rendered = []

      v = new Varying('test')
      dom = { find: (-> dom), text: ((x) -> rendered.push(x)) }
      subject = { watch: (x) -> attr = x; v }

      class TestView extends DomView
        @_dom: -> dom
        @_template: template(find('.title').text(from.attr('someattr')))

      (new TestView(subject)).artifact()
      attr.should.equal('someattr')
      rendered.should.eql([ 'test' ])

      v.set('test 2')
      rendered.should.eql([ 'test', 'test 2' ])

    it 'points definition inputs correctly', ->
      attr = null
      rendered = []

      attribute = 'test'
      dom = { find: (-> dom), text: ((x) -> rendered.push(x)) }
      subject = { attribute: (x) -> attr = x; attribute }

      class TestView extends DomView
        @_dom: -> dom
        @_template: template(find('.title').text(from.definition('test_attr')))

      (new TestView(subject)).artifact()
      attr.should.equal('test_attr')
      rendered.should.eql([ 'test' ])

    it 'points varying function inputs correctly', ->
      passed = null
      rendered = []
      v = new Varying('test')

      dom = { find: (-> dom), text: ((x) -> rendered.push(x)) }
      subject = {}

      class TestView extends DomView
        @_dom: -> dom
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

      dom = { find: (-> dom), text: ((x) -> rendered.push(x)) }
      subject = {}

      class TestView extends DomView
        @_dom: -> dom
        @_template: template(
          find('.title').text(from.varying(v))
        )

      (new TestView(subject)).artifact()
      rendered.should.eql([ 'test' ])

      v.set('test 2')
      rendered.should.eql([ 'test', 'test 2' ])

  describe 'dom events', ->
    it 'emits appendedToDocument when it is appended to body', ->
      dom = { find: (-> dom), text: (->), closest: (-> [ 42 ]) }
      class TestView extends DomView
        @_dom: -> dom
        @_template: template(find('.title').text(from.varying(42)))

      emitted = false
      view = new TestView({})
      view.on('appendedToDocument', -> emitted = true)
      view.artifact()
      emitted.should.equal(false)
      view.emit('appended')
      emitted.should.equal(true)

    it 'emits appendedToDocument only when it is appended to body', ->
      dom = { find: (-> dom), text: (->), closest: (-> []) }
      class TestView extends DomView
        @_dom: -> dom
        @_template: template(find('.title').text(from.varying(42)))

      emitted = false
      view = new TestView({})
      view.on('appendedToDocument', -> emitted = true)
      view.artifact()
      view.emit('appended')
      emitted.should.equal(false)

    it 'triggers appended events on subviews when appended to body', ->
      dom = { find: (-> dom), text: (->), closest: (-> [ 42 ]) }
      class TestView extends DomView
        @_dom: -> dom
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

  describe 'lifecycle', ->
    it 'triggers a `destroying` event on the dom fragment root', ->
      triggered = null
      dom = { find: (-> dom), text: (->), remove: (->), trigger: ((x) -> triggered = x) }

      class TestView extends DomView
        @_dom: -> dom
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
      dom = { find: (-> dom), text: (->), remove: (-> removed = true) }

      class TestView extends DomView
        @_dom: -> dom
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

      dom = { find: (-> dom), text: ((x) -> rendered.push(x)), remove: (->) }

      class TestView extends DomView
        @_dom: -> dom
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

