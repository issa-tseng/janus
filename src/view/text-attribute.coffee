{ Varying, DomView, from, template, find, Base } = require('janus')
{ Text } = require('janus').attribute

$ = require('janus-dollar')

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
    library.register(Text, TextAttributeEditView, context: 'edit')
    library.register(Text, MultilineTextAttributeEditView, context: 'edit', style: 'multiline')
}

