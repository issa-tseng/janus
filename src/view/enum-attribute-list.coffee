{ Varying, DomView, from, template, find, mutators, Base, List } = require('janus')
{ Enum } = require('janus').attribute
{ identity } = require('janus').util
{ asList } = require('../util/util')

$ = require('janus-dollar')

class EnumAttributeListEditView extends DomView.build(
  $('<div class="janus-enum-select"/>'), template(
    find('div')
      .render(from.subject().flatMap((attr) ->
        # TODO: resolve all this point stuff in core
        values = attr.values()
        values = values.all.point(attr.model.pointer()) if values.all?.point?
        return Varying.of(values).map(asList)
      ))
      # pass our options along so that eg renderItem gets picked up.
      .options(from.self().map((view) -> view.options))
    )
  )

  _wireEvents: ->
    list = this.artifact().children(':first')
    list.on('click', '> *', (event) =>
      return if event.isDefaultPrevented() is true
      this.subject.setValue($(event.currentTarget).data('view').subject)
    )
    return


module.exports = {
  EnumAttributeListEditView
  registerWith: (library) ->
    library.register(Enum, EnumAttributeListEditView, context: 'edit', style: 'list')
}


