should = require('should')

{ Varying, Model, attribute } = require('janus')
{ App, Library } = require('janus').application
{ BooleanAttributeEditView, BooleanButtonAttributeEditView } = require('../../lib/view/boolean-attribute')

$ = require('../../lib/util/dollar')

describe 'view', ->
  describe 'boolean attribute', ->
    it 'renders an input tag of the appropriate type', ->
      dom = (new BooleanAttributeEditView(new attribute.BooleanAttribute(new Model(), 'test'))).artifact()
      dom.is('input').should.equal(true)
      dom.attr('type').should.equal('checkbox')

    it 'renders the input with the correct initial value', ->
      dom = (new BooleanAttributeEditView(new attribute.BooleanAttribute(new Model({ test: false }), 'test'))).artifact()
      dom.is(':checked').should.equal(false)

      dom = (new BooleanAttributeEditView(new attribute.BooleanAttribute(new Model({ test: true }), 'test'))).artifact()
      dom.is(':checked').should.equal(true)

    it 'updates the model value when changed', ->
      m = new Model({ test: false })
      view = new BooleanAttributeEditView(new attribute.BooleanAttribute(m, 'test'))
      dom = view.artifact()
      view.wireEvents()

      m.get('test').should.equal(false)

      dom.prop('checked', true)
      dom.trigger('change')
      m.get('test').should.equal(true)

      # due to a bug in domino, an input once checked cannot be unchecked.
      # https://github.com/fgnass/domino/pull/91
      ###
      dom.prop('checked', false)
      dom.trigger('change')
      m.get('test').should.equal(false)
      ###

    it 'is updated when the model value changes', ->
      m = new Model({ test: false })
      view = new BooleanAttributeEditView(new attribute.BooleanAttribute(m, 'test'))
      dom = view.artifact()
      view.wireEvents()

      dom.is(':checked').should.equal(false)

      m.set('test', true)
      dom.is(':checked').should.equal(true)

      # due to a bug in domino, an input once checked cannot be unchecked.
      # https://github.com/fgnass/domino/pull/91
      ###
      m.set('test', false)
      dom.is(':checked').should.equal(false)
      ###

  describe 'boolean attribute (button)', ->
    it 'renders an button tag', ->
      dom = (new BooleanButtonAttributeEditView(new attribute.BooleanAttribute(new Model(), 'test'))).artifact()
      dom.is('button').should.equal(true)

    it 'renders the button with the correct initial value', ->
      dom = (new BooleanButtonAttributeEditView(new attribute.BooleanAttribute(new Model({ test: false }), 'test'))).artifact()
      dom.hasClass('checked').should.equal(false)

      dom = (new BooleanButtonAttributeEditView(new attribute.BooleanAttribute(new Model({ test: true }), 'test'))).artifact()
      dom.hasClass('checked').should.equal(true)

    it 'updates the model value when changed', ->
      m = new Model({ test: false })
      view = new BooleanButtonAttributeEditView(new attribute.BooleanAttribute(m, 'test'))
      dom = view.artifact()
      view.wireEvents()

      m.get('test').should.equal(false)

      dom.click()
      m.get('test').should.equal(true)
      dom.hasClass('checked').should.equal(true)

      dom.click()
      m.get('test').should.equal(false)
      dom.hasClass('checked').should.equal(false)

    it 'updates the model value when changed', ->
      m = new Model({ test: false })
      dom = (new BooleanButtonAttributeEditView(new attribute.BooleanAttribute(m, 'test'))).artifact()

      dom.hasClass('checked').should.equal(false)
      m.set('test', true)
      dom.hasClass('checked').should.equal(true)
      m.set('test', false)
      dom.hasClass('checked').should.equal(false)

    it 'uses toString for text content by default', ->
      m = new Model({ test: false })
      dom = (new BooleanButtonAttributeEditView(new attribute.BooleanAttribute(m, 'test'))).artifact()

      dom.text().should.equal('false')
      m.set('test', true)
      dom.text().should.equal('true')

    it 'uses view.options.stringify for text content if available', ->
      m = new Model({ test: false })
      stringify = (x) -> { true: 'yes', false: 'no' }[x]
      dom = (new BooleanButtonAttributeEditView(new attribute.BooleanAttribute(m, 'test'), { stringify })).artifact()

      dom.text().should.equal('no')
      m.set('test', true)
      dom.text().should.equal('yes')

    it 'uses attribute#stringify for text content if available', ->
      class TestAttribute extends attribute.BooleanAttribute
        stringify: (x) -> { true: 'yes', false: 'no' }[x]
      m = new Model({ test: false })
      dom = (new BooleanButtonAttributeEditView(new TestAttribute(m, 'test'))).artifact()

      dom.text().should.equal('no')
      m.set('test', true)
      dom.text().should.equal('yes')

    it 'prefers options.stringify over attribute#stringify for text content', ->
      class TestAttribute extends attribute.BooleanAttribute
        stringify: (x) -> { true: 'yes', false: 'no' }[x]
      m = new Model({ test: false })
      stringify = (x) -> { true: 'oui', false: 'non' }[x]
      dom = (new BooleanButtonAttributeEditView(new TestAttribute(m, 'test'), { stringify })).artifact()

      dom.text().should.equal('non')
      m.set('test', true)
      dom.text().should.equal('oui')

