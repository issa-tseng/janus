{ Varying, DomView, from, template, find, Base } = require('janus')
{ Boolean } = require('janus').attribute
{ stringifier } = require('../util/util')

$ = require('janus-dollar')

BooleanAttributeEditView = DomView.build($('<input type="checkbox"/>'), template(
  find('input')
    .prop('checked', from.self().flatMap((view) -> view.subject.getValue()))
    .on('input change', (event, subject) -> subject.setValue(event.target.checked))
))

BooleanButtonAttributeEditView = DomView.build($('<button/>'), template(
  find('button')
    .text(from.self().flatMap(stringifier)
      .and.self().flatMap((view) -> view.subject.getValue())
      .all.map((f, value) -> f(value)))

    .classed('checked', from.self().flatMap((view) -> view.subject.getValue()))

    .on('click', (event, subject) ->
      event.preventDefault()
      subject.setValue(!subject.getValue_())
    )
))

module.exports = {
  BooleanAttributeEditView,
  BooleanButtonAttributeEditView,
  registerWith: (library) ->
    library.register(Boolean, BooleanAttributeEditView, context: 'edit')
    library.register(Boolean, BooleanButtonAttributeEditView, context: 'edit', style: 'button')
}

