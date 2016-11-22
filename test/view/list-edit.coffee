should = require('should')

{ Varying, DomView, template, find, from, List } = require('janus')
{ App, Library } = require('janus').application
{ ListEditView, ListEditItemView } = require('../../lib/view/list-edit')

$ = require('../../lib/util/dollar')

# register LiteralView for our tests to make our lives easier.
testLibrary = new Library()
testLibrary.register(Number, require('../../lib/view/literal').LiteralView, context: 'edit')
testLibrary.register(Number, ListEditItemView, context: 'edit-wrapper')
testApp = (new App()).withViewLibrary(testLibrary)

checkLiteral = (dom, expectedText) ->
  dom.is('span').should.equal(true)
  dom.hasClass('janus-literal').should.equal(true)
  dom.text().should.equal(expectedText.toString())

checkEditItem = (dom, checkInner) ->
  dom.is('div').should.equal(true)
  dom.children().length.should.equal(5)
  checkInner(dom.find('> .janus-list-editItem-contents > :first-child'))

describe 'view', ->
  describe 'list edit', ->
    it 'should render an unordered list element of the appropriate classes', ->
      dom = (new ListEditView(new List())).artifact()
      dom.is('ul').should.equal(true)
      dom.hasClass('janus-list').should.equal(true)
      dom.hasClass('janus-list-edit').should.equal(true)

    it 'should render items wrapped in the edit item view', ->
      dom = (new ListEditView(new List([ 1, 2 ]), { app: testApp })).artifact()
      dom.children().length.should.equal(2)
      for idx in [0..1]
        li = dom.children().eq(idx)
        li.children().length.should.equal(1)
        checkEditItem(li.children(':first-child'), (inner) -> checkLiteral(inner, (idx + 1).toString()))

    # we kind of take on faith that derived behaviour from ListView with regards
    # to adding/removing elements will function, especially as our code does not
    # override those processes at all.

    it 'should allow chaining on its item render mutator', ->
      library = new Library()
      library.register(Number, require('../../lib/view/literal').LiteralView, context: 'custom')
      library.register(Number, ListEditItemView, context: 'edit-wrapper')
      app = (new App()).withViewLibrary(library)

      renderItem = (render) -> render.context('custom')
      dom = (new ListEditView(new List([ 1, 2 ]), { app, renderItem })).artifact()

      targets = dom.find('> li > .janus-list-editItem > .janus-list-editItem-contents > .janus-literal')
      targets.length.should.equal(2)
      for idx in [0..1]
        checkLiteral(targets.eq(idx), (idx + 1).toString())

    it 'should allow chaining on its wrapper render mutator', ->
      library = new Library()
      library.register(Number, require('../../lib/view/literal').LiteralView, context: 'edit')
      library.register(Number, ListEditItemView, context: 'custom')
      app = (new App()).withViewLibrary(library)

      renderWrapper = (render) -> render.context('custom')
      dom = (new ListEditView(new List([ 1, 2 ]), { app, renderWrapper })).artifact()

      targets = dom.find('> li > .janus-list-editItem')
      targets.length.should.equal(2)
      for idx in [0..1]
        checkEditItem(targets.eq(idx), (inner) -> checkLiteral(inner, (idx + 1).toString()))

    it 'should remove if the remove link is clicked', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      view = new ListEditView(l, { app: testApp })
      dom = view.artifact()
      view.wireEvents()

      dom.children().eq(2).find('.janus-list-editItem-remove').click()
      l.list.should.eql([ 1, 2, 4, 5 ])

      dom.children().length.should.equal(4)
      targets = dom.find('> li > .janus-list-editItem')
      for label, idx in [ 1, 2, 4, 5 ]
        checkEditItem(targets.eq(idx), (inner) -> checkLiteral(inner, label.toString()))

    it 'should dim the appropriate move buttons', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      dom = (new ListEditView(l, { app: testApp })).artifact()

      dom.find('.janus-list-editItem-moveUp.disabled').length.should.equal(1)
      dom.find('> :first-child .janus-list-editItem-moveUp.disabled').length.should.equal(1)

      dom.find('.janus-list-editItem-moveDown.disabled').length.should.equal(1)
      dom.find('> :last-child .janus-list-editItem-moveDown.disabled').length.should.equal(1)

      l.removeAt(0)
      l.removeAt(3)

      dom.find('.janus-list-editItem-moveUp.disabled').length.should.equal(1)
      dom.find('> :first-child .janus-list-editItem-moveUp.disabled').length.should.equal(1)

      dom.find('.janus-list-editItem-moveDown.disabled').length.should.equal(1)
      dom.find('> :last-child .janus-list-editItem-moveDown.disabled').length.should.equal(1)

    it 'should move an item up when move up is clicked', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      view = new ListEditView(l, { app: testApp })
      dom = view.artifact()
      view.wireEvents()

      dom.children().eq(2).find('.janus-list-editItem-moveUp').click()
      l.list.should.eql([ 1, 3, 2, 4, 5 ])

      dom.children().length.should.equal(5)
      targets = dom.find('> li > .janus-list-editItem')
      for label, idx in [ 1, 3, 2, 4, 5 ]
        checkEditItem(targets.eq(idx), (inner) -> checkLiteral(inner, label.toString()))

    it 'should move an item down when move down is clicked', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      view = new ListEditView(l, { app: testApp })
      dom = view.artifact()
      view.wireEvents()

      dom.children().eq(2).find('.janus-list-editItem-moveDown').click()
      l.list.should.eql([ 1, 2, 4, 3, 5 ])

      dom.children().length.should.equal(5)
      targets = dom.find('> li > .janus-list-editItem')
      for label, idx in [ 1, 2, 4, 3, 5 ]
        checkEditItem(targets.eq(idx), (inner) -> checkLiteral(inner, label.toString()))

    it 'should not attempt to move an item if it is at the end', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      view = new ListEditView(l, { app: testApp })
      dom = view.artifact()
      view.wireEvents()

      dom.children().eq(0).find('.janus-list-editItem-moveUp').click()
      dom.children().eq(4).find('.janus-list-editItem-moveDown').click()

      l.list.should.eql([ 1, 2, 3, 4, 5 ])

      dom.children().length.should.equal(5)
      targets = dom.find('> li > .janus-list-editItem')
      for label, idx in [ 1, 2, 3, 4, 5 ]
        checkEditItem(targets.eq(idx), (inner) -> checkLiteral(inner, label.toString()))

    it 'should accept external notifications that a node has moved (li)', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      view = new ListEditView(l, { app: testApp })
      dom = view.artifact()
      view.wireEvents()

      # need to fake out the appended handler.
      $('body').append(dom)
      view.emit('appended')

      # move the third element to the top.
      target = dom.children().eq(2)
      dom.prepend(target)
      target.trigger('janus-itemMoved')

      l.list.should.eql([ 3, 1, 2, 4, 5 ])
      targets = dom.find('> li > .janus-list-editItem .janus-literal')
      for label, idx in [ 3, 1, 2, 4, 5 ]
        checkLiteral(targets.eq(idx), label.toString())

    it 'should accept external notifications that a node has moved (wrapper)', ->
      l = new List([ 1, 2, 3, 4, 5 ])
      view = new ListEditView(l, { app: testApp })
      dom = view.artifact()
      view.wireEvents()

      # need to fake out the appended handler.
      $('body').append(dom)
      view.emit('appended')

      # move the third element to the top.
      target = dom.children().eq(2)
      dom.prepend(target)
      target.find('.janus-list-editItem').trigger('janus-itemMoved')

      l.list.should.eql([ 3, 1, 2, 4, 5 ])
      targets = dom.find('> li > .janus-list-editItem .janus-literal')
      for label, idx in [ 3, 1, 2, 4, 5 ]
        checkLiteral(targets.eq(idx), label.toString())

