{ Varying, DomView, from, template, find, Base } = require('janus')
{ BooleanAttribute } = require('janus').attribute
{ stringifier } = require('../util/util')

$ = require('../util/dollar')

BooleanAttributeEditView = DomView.build($('<input type="checkbox"/>'), template(
  find('input')
    .prop('checked', from.self().flatMap((view) -> view.subject.watchValue()))
    .on('input change', (event, subject) -> subject.setValue(event.target.checked))
))

BooleanButtonAttributeEditView = DomView.build($('<button/>'), template(
  find('button')
    .text(from.self().flatMap(stringifier)
      .and.self().flatMap((view) -> view.subject.watchValue())
      .all.map((f, value) -> f(value)))

    .classed('checked', from.self().flatMap((view) -> view.subject.watchValue()))

    .on('click', (event, subject) ->
      event.preventDefault()
      subject.setValue(!subject.getValue())
    )
))

module.exports = {
  BooleanAttributeEditView,
  BooleanButtonAttributeEditView,
  registerWith: (library) ->
    library.register(BooleanAttribute, BooleanAttributeEditView, context: 'edit')
    library.register(BooleanAttribute, BooleanButtonAttributeEditView, context: 'edit', attributes: { style: 'button' })
}

