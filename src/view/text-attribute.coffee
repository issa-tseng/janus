{ Varying, DomView, from, template, find, Base } = require('janus')
{ TextAttribute } = require('janus').attribute

$ = require('../util/dollar')

class TextAttributeEditView extends DomView
  @_dom: -> $('<input/>')
  @_template: template(
    find('input').attr('type', from.self().map((view) -> view.options.type ? 'text'))
    find('input').attr('placeholder', from.self().flatMap((view) -> view.options.placeholder ? ''))
  )

  _updateVal = (input, subject) -> input.val(subject.getValue()) unless input.hasClass('focus')
  eventsFor = { 'all': 'input change', 'commit': 'change' }

  # splice into here just so we can initially set the value. we can't do a full
  # binding, as that would cause weird event loops while typing.
  _render: ->
    dom = super()
    _updateVal(dom, this.subject)
    dom

  _wireEvents: ->
    input = this.artifact()
    subject = this.subject

    # update the input if the value changes. reactNow in case it has changed since
    # initial rendering and event wiring.
    this.subject.watchValue().reactNow(-> _updateVal(input, subject))

    # update the input's focus. we use classes as they are more easily testable in
    # flimsier/faster dom emulation frameworks.
    input.on('focus', -> input.addClass('focus'))
    input.on('blur', -> input.removeClass('focus'))

    # update the value on input change.
    input.on(eventsFor[this.options.update ? 'all'], -> subject.setValue(input.val()))

class MultilineTextAttributeEditView extends TextAttributeEditView
  @_dom: -> $('<textarea/>')

module.exports = {
  TextAttributeEditView,
  MultilineTextAttributeEditView,
  registerWith: (library) ->
    library.register(TextAttribute, TextAttributeEditView, context: 'edit')
    library.register(TextAttribute, MultilineTextAttributeEditView, context: 'edit', attributes: { style: 'multiline' })
}

