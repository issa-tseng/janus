{ DomView } = require('janus')
{ Number } = require('janus').attribute
{ TextAttributeEditView } = require('./text-attribute')

$ = require('janus-dollar')

NumberAttributeEditView = DomView.build(
  $('<input/>'),
  TextAttributeEditView._baseTemplate(
    'number',
    (event, subject) -> subject.setValue(parseFloat(event.target.value))
  )
)

module.exports = { NumberAttributeEditView, registerWith: (library) -> library.register(Number, NumberAttributeEditView, context: 'edit') }

