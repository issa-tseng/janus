should = require('should')

{ Varying, DomView, template, find, from, List } = require('janus')
{ App, Library } = require('janus').application
{ ListView } = require('../../lib/view/list')

$ = require('../../lib/util/dollar')

# register LiteralView for our tests to make our lives easier.
testLibrary = new Library()
require('../../lib/view/literal').registerWith(testLibrary)
testApp = (new App()).withViewLibrary(testLibrary)

checkLiteral = (dom, expectedText) ->
  dom.is('span').should.equal(true)
  dom.hasClass('janus-literal').should.equal(true)
  dom.text().should.equal(expectedText.toString())

describe 'view', ->
  describe 'list', ->
    it 'should render an unordered list element of the appropriate class', ->
      dom = (new ListView(new List())).artifact()
      dom.is('ul').should.equal(true)
      dom.hasClass('janus-list').should.equal(true)

    it 'should initially display the appropriate elements', ->
      dom = (new ListView(new List([ 1, 2, 3 ]), { app: testApp })).artifact()
      dom.children().length.should.equal(3)

      for i in [0..2]
        child = dom.children().eq(i)
        child.is('li').should.equal(true)
        child.children().length.should.equal(1)

        checkLiteral(child.children(':first-child'), i + 1)

    it 'should correctly add new elements', ->
      l = new List([ 1, 2, 3 ])
      dom = (new ListView(l, { app: testApp })).artifact()

      l.add(4)
      dom.children().length.should.equal(4)
      itemDom = dom.children('li:last-child')
      itemDom.children().length.should.equal(1)
      checkLiteral(itemDom.children(':first-child'), 4)

      l.add(5, 1)
      dom.children().length.should.equal(5)
      itemDom = dom.children(':nth-child(2)') # nth-child is 1-indexed
      itemDom.children().length.should.equal(1)
      checkLiteral(itemDom.children(':first-child'), 5)

    it 'should correctly remove elements', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      dom = (new ListView(l, { app: testApp })).artifact()

      l.remove(3)
      dom.children().length.should.equal(4)
      for label, idx in [ 1, 2, 4, 5 ]
        itemDom = dom.children().eq(idx)
        itemDom.is('li').should.equal(true)
        itemDom.children().length.should.equal(1)
        checkLiteral(itemDom.children(':first-child'), label)

    it 'should destroy views related to removed elements', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      dom = (new ListView(l, { app: testApp })).artifact()

      destroyed = false
      victimView = dom.children().eq(2).data('subview')
      victimView.on('destroying', -> destroyed = true)

      l.remove(3)
      destroyed.should.equal(true)

    it 'should unbind the render mutator related to removed elements', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      view = new ListView(l, { app: testApp })
      dom = view.artifact()

      unbound = false
      victimMutator = view._bindings[2]
      victimMutator.stop = -> unbound = true

      l.remove(3)
      unbound.should.equal(true)

    it 'should react appropriately when a Varying item changes', ->
      l = new List([ 1, new Varying(2), 3 ])
      dom = (new ListView(l, { app: testApp })).artifact()

      l.at(1).set('test')
      dom.children().length.should.equal(3)
      itemDom = dom.children().eq(1)
      itemDom.is('li').should.equal(true)
      itemDom.children().length.should.equal(1)
      checkLiteral(itemDom.children(':first-child'), 'test')

    it 'should allow chaining on its render mutator', ->
      l = new List([ 1, 2, 3 ])
      renderItem = (render) -> render.context('test')

      library = new Library()
      library.register(Number, require('../../lib/view/literal').LiteralView, context: 'test')
      app = (new App()).withViewLibrary(library)

      dom = (new ListView(l, { app, renderItem })).artifact()

      dom.children().length.should.equal(3)
      for i in [0..2]
        child = dom.children().eq(i)
        child.is('li').should.equal(true)
        child.children().length.should.equal(1)

        checkLiteral(child.children(':first-child'), i + 1)

