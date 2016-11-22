{ NumberAttribute } = require('janus').attribute
{ TextAttributeEditView } = require('./text-attribute')

class NumberAttributeEditView extends TextAttributeEditView
  _initialize: -> this.options.type ?= 'number'

module.exports = { NumberAttributeEditView, registerWith: (library) -> library.register(NumberAttribute, NumberAttributeEditView, context: 'edit') }

