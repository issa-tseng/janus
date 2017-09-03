should = require('should')

{ Varying, DomView, template, find, from, types } = require('janus')
{ App, Library } = require('janus').application
{ SuccessResultView, registerWith } = require('../../lib/view/types')

$ = require('../../lib/util/dollar')

dummyApp = new App()

describe 'view', ->
  describe 'types', ->
    describe 'success', ->
      it 'renders its container div', ->
        view = new SuccessResultView(types.result.success, { app: dummyApp })

        dom = view.artifact()
        dom.is('div').should.equal(true)
        dom.hasClass('janus-successResult').should.equal(true)

      it 'renders the case value', ->
        library = new Library()
        require('../../lib/view/literal').registerWith(library)
        app = new App( views: library )
        view = new SuccessResultView(types.result.success(47), { app: app })

        dom = view.artifact()
        dom.children().length.should.equal(1)
        inner = dom.children('span')
        inner.hasClass('janus-literal').should.equal(true)
        inner.text().should.equal('47')

      it 'registers the case class correctly', ->
        library = new Library()
        registerWith(library)

        library.get(types.result.success).should.be.an.instanceof(SuccessResultView)
        library.get(types.result.success()).should.be.an.instanceof(SuccessResultView)

