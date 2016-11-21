should = require('should')

{ Varying, DomView, template, find, from } = require('janus')
{ App, Library } = require('janus').application
{ VaryingView } = require('../../lib/view/varying')

$ = require('../../lib/util/dollar')

dummyApp = (new App()).withViewLibrary(new Library())

describe 'view', ->
  describe 'varying', ->
    it 'should render a div of the appropriate class', ->
      view = new VaryingView(new Varying(1), { app: dummyApp })

      dom = view.artifact()
      dom.is('div').should.equal(true)
      dom.hasClass('janus-varying').should.equal(true)

    it 'should render an appropriate view initially', ->
      class NumberView extends DomView
        @_dom: -> $('<span class="janus-test"/>')
        @_template: template(find('span').text(from((subject) -> subject)))

      library = new Library()
      library.register(Number, NumberView)
      app = (new App()).withViewLibrary(library)

      view = new VaryingView(new Varying(1), { app })
      dom = view.artifact()
      dom.children('span.janus-test').length.should.equal(1)
      dom.children().length.should.equal(1)

    it 'should handle a view change correctly', ->
      class LiteralView1 extends DomView
        @_dom: -> $('<span class="janus-test1"/>')
        @_template: template(find('span').text(from((subject) -> subject)))
      class LiteralView2 extends LiteralView1
        @_dom: -> $('<span class="janus-test2"/>')

      library = new Library()
      library.register(Number, LiteralView1)
      library.register(String, LiteralView2)
      app = (new App()).withViewLibrary(library)

      v = new Varying(1)
      view = new VaryingView(v, { app })
      dom = view.artifact()
      dom.children('span.janus-test1').length.should.equal(1)

      v.set('hello')
      dom.children('span.janus-test2').length.should.equal(1)
      dom.children('span.janus-test1').length.should.equal(0)
      dom.children().length.should.equal(1)

    it 'should empty out if no view is to be had', ->
      class NumberView extends DomView
        @_dom: -> $('<span class="janus-test"/>')
        @_template: template(find('span').text(from((subject) -> subject)))

      library = new Library()
      library.register(Number, NumberView)
      app = (new App()).withViewLibrary(library)

      v = new Varying(1)
      view = new VaryingView(v, { app })
      dom = view.artifact()
      dom.children('span.janus-test').length.should.equal(1)

      v.set('test')
      dom.children('span.janus-test').length.should.equal(0)
      dom.children().length.should.equal(0)

