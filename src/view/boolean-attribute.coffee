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

class BooleanButtonAttributeEditView extends DomView
  @_dom: -> $('<button/>')
  @_template: template(
    find('button').text(
      from.self().flatMap((view) -> view.stringify())
        .and.self().flatMap((view) -> view.subject.watchValue())
        .all.map((f, value) -> f(value)))

    find('button').classed('checked', from.self().flatMap((view) -> view.subject.watchValue()))
  )

  stringify: -> this.stringify$ ?= do =>
    # prefer options.stringify, then attribute.stringify, fall back to toString.
    if this.options.stringify?
      Varying.ly(this.options.stringify)
    else if this.subject.stringify?
      Varying.ly(this.subject.stringify)
    else
      new Varying((x) -> x?.toString())

  _wireEvents: ->
    dom = this.artifact()

    dom.on('click', (event) =>
      event.preventDefault() # prevent submits in forms.
      this.subject.setValue(!this.subject.getValue())
    )

module.exports = {
  BooleanAttributeEditView,
  BooleanButtonAttributeEditView,
  registerWith: (library) ->
    library.register(BooleanAttribute, BooleanAttributeEditView, context: 'edit')
    library.register(BooleanAttribute, BooleanButtonAttributeEditView, context: 'edit', attributes: { style: 'button' })
}

