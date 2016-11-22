{ Varying, DomView, from, template, find, Base } = require('janus')
{ BooleanAttribute } = require('janus').attribute

$ = require('../util/dollar')

class BooleanAttributeEditView extends DomView
  @_dom: -> $('<input type="checkbox"/>')
  @_template: -> ->

  _updateVal = (input, subject) -> input.prop('checked', subject.getValue() is true)

  # splice into here so we can set the initial value, and because we don't have
  # a mutator for #prop(). (should we?)
  _render: ->
    dom = super()
    _updateVal(dom, this.subject)
    dom

  _wireEvents: ->
    input = this.artifact()
    subject = this.subject

    subject.watchValue().reactNow(-> _updateVal(input, subject))
    input.on('input change', -> subject.setValue(input.prop('checked')))

module.exports = {
  BooleanAttributeEditView,
  registerWith: (library) ->
    library.register(BooleanAttribute, BooleanAttributeEditView, context: 'edit')
}

