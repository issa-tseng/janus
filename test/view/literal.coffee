should = require('should')

{ Varying, DomView, template, find, from } = require('janus')
{ App, Library } = require('janus').application
{ LiteralView, registerWith } = require('../../lib/view/literal')

$ = require('../../lib/util/dollar')

dummyApp = new App()

describe 'view', ->
  describe 'literal', ->
    it 'renders as expected for string values', ->
      view = new LiteralView('test', { app: dummyApp })

      dom = view.artifact()
      dom.is('span').should.equal(true)
      dom.hasClass('janus-literal').should.equal(true)
      dom.text().should.equal('test')

    it 'renders as expected for number values', ->
      view = new LiteralView(42, { app: dummyApp })

      dom = view.artifact()
      dom.is('span').should.equal(true)
      dom.hasClass('janus-literal').should.equal(true)
      dom.text().should.equal('42')

    it 'renders as expected for boolean values', ->
      view = new LiteralView(false, { app: dummyApp })

      dom = view.artifact()
      dom.is('span').should.equal(true)
      dom.hasClass('janus-literal').should.equal(true)
      dom.text().should.equal('false')

    it 'registers its primitives correctly', ->
      library = new Library()
      registerWith(library)

      library.get(42).should.be.an.instanceof(LiteralView)
      library.get('test').should.be.an.instanceof(LiteralView)
      library.get(true).should.be.an.instanceof(LiteralView)

