{ Varying, DomView, from, template, find, Base } = require('janus')
{ TextAttribute } = require('janus').attribute

$ = require('../util/dollar')

TextAttributeEditView = DomView.build($('<input/>'), template(
  find('input')
    .attr('type', from.self().map((view) -> view.options.type ? 'text'))
    .attr('placeholder', from.self().flatMap((view) -> view.options.placeholder ? ''))
    .prop('value', from((subject) -> subject.watchValue()))

    .on('input change', (event, subject) -> subject.setValue(event.target.value))
))

class MultilineTextAttributeEditView extends TextAttributeEditView
  dom: -> $('<textarea/>')

module.exports = {
  TextAttributeEditView,
  MultilineTextAttributeEditView,
  registerWith: (library) ->
    library.register(TextAttribute, TextAttributeEditView, context: 'edit')
    library.register(TextAttribute, MultilineTextAttributeEditView, context: 'edit', attributes: { style: 'multiline' })
}

