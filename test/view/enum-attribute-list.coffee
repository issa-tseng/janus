should = require('should')

{ Varying, DomView, template, find, from, List, Set, App, Library, Model, attribute } = require('janus')
{ ListView, SetView } = require('../../lib/view/list')
{ EnumAttributeListEditView } = require('../../lib/view/enum-attribute-list')

$ = require('janus-dollar')

# register ListView, TestModelView, and LiteralView for our tests to make our lives easier.
testLibrary = new Library()
testLibrary.register(List, ListView)
require('../../lib/view/literal').registerWith(testLibrary)
testApp = new App( views: testLibrary )

checkLiteral = (dom, expectedText) ->
  dom.is('span').should.equal(true)
  dom.hasClass('janus-literal').should.equal(true)
  dom.text().should.equal(expectedText.toString())

describe 'view', ->
  describe 'enum attribute (list)', ->
    it 'should render the list as normal', ->
      class TestAttribute extends attribute.Enum
        values: -> [ 1, 2, 3 ]
      dom = (new EnumAttributeListEditView(new TestAttribute(new Model(), 'test'), { app: testApp })).artifact()

      list = dom.children().eq(0)
      list.contents().length.should.equal(3)
      for label, idx in [ 1, 2, 3 ]
        checkLiteral(list.contents().eq(idx), label)

    it 'should should resolve from bindings', ->
      class TestAttribute extends attribute.Enum
        values: -> from('options').map((l) -> l.map((x) -> x * 2))
      model = new Model({ options: new List([ 1, 2 ]) })
      dom = (new EnumAttributeListEditView(new TestAttribute(model, 'test'), { app: testApp })).artifact()
      list = dom.children().eq(0)

      list.contents().length.should.equal(2)
      for label, idx in [ 2, 4 ]
        checkLiteral(list.contents().eq(idx), label)

      model.get_('options').add(3, 1)
      list.contents().length.should.equal(3)
      for label, idx in [ 2, 6, 4 ]
        checkLiteral(list.contents().eq(idx), label)

    it 'should set the attribute value when click occurs', ->
      class TestAttribute extends attribute.Enum
        values: -> [ 1, 2, 3 ]
      model = new Model()
      view = new EnumAttributeListEditView(new TestAttribute(model, 'test'), { app: testApp })
      dom = view.artifact()
      view.wireEvents()

      dom.children().eq(0).children().eq(1).trigger('click')
      model.get_('test').should.equal(2)
      dom.children().eq(0).children().eq(2).trigger('click')
      model.get_('test').should.equal(3)

    it 'should not set the attribute value if the event has default prevented', ->
      class TestAttribute extends attribute.Enum
        values: -> [ 1, 2, 3 ]
      model = new Model()
      view = new EnumAttributeListEditView(new TestAttribute(model, 'test'), { app: testApp })
      dom = view.artifact()
      view.wireEvents()
      dom.find('span').on('click', (event) -> event.preventDefault())

      dom.children().eq(0).children().eq(1).trigger('click')
      (model.get_('test')?).should.equal(false)

