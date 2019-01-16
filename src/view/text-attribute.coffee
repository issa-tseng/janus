{ Varying, DomView, from, template, find, Base } = require('janus')
{ Text } = require('janus').attribute

$ = require('janus-dollar')

textAttributeTemplate = (type, handler) -> template(
  find('input')
    .attr('type', from.self().map((view) -> view.options.type ? type))
    .attr('placeholder', from.self().flatMap((view) -> view.options.placeholder ? ''))
    .prop('value', from((subject) -> subject.watchValue().map((x) -> x ? '')))

    .on('input change', handler)
)

TextAttributeEditView = DomView.build(
  $('<input/>'),
  textAttributeTemplate('text', (event, subject) -> subject.setValue(event.target.value))
)
TextAttributeEditView._baseTemplate = textAttributeTemplate

class MultilineTextAttributeEditView extends TextAttributeEditView
  dom: -> $('<textarea/>')

module.exports = {
  TextAttributeEditView,
  MultilineTextAttributeEditView,
  registerWith: (library) ->
    library.register(Text, TextAttributeEditView, context: 'edit')
    library.register(Text, MultilineTextAttributeEditView, context: 'edit', style: 'multiline')
}

