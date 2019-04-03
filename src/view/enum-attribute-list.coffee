{ Varying, DomView, from, template, find, mutators, Base, List } = require('janus')
{ Enum } = require('janus').attribute
{ identity } = require('janus').util

$ = require('janus-dollar')

class EnumAttributeListEditView extends DomView.build(
  $('<div class="janus-enum-select"/>')

  find('div').render(from.subject().flatMap((attr) -> attr.values()))
    # pass our options along so that eg renderItem gets picked up.
    .options(from.self().map((view) -> view.options))
)

  _wireEvents: ->
    list = this.artifact()
    list.on('click', '> .janus-list > *', (event) =>
      return if event.isDefaultPrevented() is true
      this.subject.setValue($(event.currentTarget).data('view').subject)
    )
    return


module.exports = {
  EnumAttributeListEditView
  registerWith: (library) ->
    library.register(Enum, EnumAttributeListEditView, context: 'edit', style: 'list')
}


