should = require('should')

{ Varying, Model, attribute } = require('janus')
{ App, Library } = require('janus').application
{ BooleanAttributeEditView } = require('../../lib/view/boolean-attribute')

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
      ###
      m.set('test', false)
      dom.is(':checked').should.equal(false)
      ###

