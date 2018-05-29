should = require('should')

{ Varying, DomView, template, find, from } = require('janus')
{ App, Library } = require('janus').application
{ VaryingView } = require('../../lib/view/varying')

$ = require('../../lib/util/dollar')

dummyApp = new App()

describe 'view', ->
  describe 'varying', ->
    it 'should render a div of the appropriate class', ->
      view = new VaryingView(new Varying(1), { app: dummyApp })

      dom = view.artifact()
      dom.is('div').should.equal(true)
      dom.hasClass('janus-varying').should.equal(true)

    it 'should render an appropriate view initially', ->
      NumberView = DomView.build($('<span class="janus-test"/>'), template(
        find('span').text(from((subject) -> subject))
      ))

      library = new Library()
      library.register(Number, NumberView)
      app = new App( views: library )

      view = new VaryingView(new Varying(1), { app })
      dom = view.artifact()
      dom.children('span.janus-test').length.should.equal(1)
      dom.children().length.should.equal(1)

    it 'should handle a view change correctly', ->
      basicTemplate = template(find('span').text(from((subject) -> subject)))
      LiteralView1 = DomView.build($('<span class="janus-test1"/>'), basicTemplate)
      LiteralView2 = DomView.build($('<span class="janus-test2"/>'), basicTemplate)

      library = new Library()
      library.register(Number, LiteralView1)
      library.register(String, LiteralView2)
      app = new App( views: library )

      v = new Varying(1)
      view = new VaryingView(v, { app })
      dom = view.artifact()
      dom.children('span.janus-test1').length.should.equal(1)

      v.set('hello')
      dom.children('span.janus-test2').length.should.equal(1)
      dom.children('span.janus-test1').length.should.equal(0)
      dom.children().length.should.equal(1)

    it 'should empty out if no view is to be had', ->
      NumberView = DomView.build($('<span class="janus-test"/>'), template(
        find('span').text(from((subject) -> subject))
      ))

      library = new Library()
      library.register(Number, NumberView)
      app = new App( views: library )

      v = new Varying(1)
      view = new VaryingView(v, { app })
      dom = view.artifact()
      dom.children('span.janus-test').length.should.equal(1)

      v.set('test')
      dom.children('span.janus-test').length.should.equal(0)
      dom.children().length.should.equal(0)

    it 'should attempt to pass its library context to its child', ->
      NumberView = DomView.build($('<span class="janus-test"/>'), template(
        find('span').text(from((subject) -> subject))
      ))

      library = new Library()
      library.register(Number, NumberView, context: 'custom')
      library.register(Varying, VaryingView)
      app = new App( views: library )

      v = new Varying(1)
      view = library.get(v, context: 'custom', options: { app })
      dom = view.artifact()
      dom.children('span.janus-test').length.should.equal(1)

