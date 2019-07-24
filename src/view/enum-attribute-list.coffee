{ Varying, DomView, from, template, find, mutators, Base, List } = require('janus')
{ Enum } = require('janus').attribute
{ identity } = require('janus').util
{ ListView } = require('./list')

$ = require('janus-dollar')

class EnumAttributeListEditView extends DomView.build(
  $('<div class="janus-enum-select"/>')

  find('div').render(from.subject().flatMap((attr) -> attr.values()))
    # pass our options along so that eg renderItem gets picked up.
    .options(from.self().map((view) -> view.options))
)

  _wireEvents: ->
    attr = this.subject
    dom = this.artifact()

    dom.on('click', '> .janus-list > *', (event) =>
      return if event.isDefaultPrevented() is true
      this.subject.setValue($(event.currentTarget).data('view').subject)
    )

    list = dom.children(':first')
    listView = this.into_(ListView)
    checkedClass = this.options.checkedClass ? 'checked'
    this.reactTo(Varying.all([ attr.values(), attr.getValue() ]), (values, selected) =>
      list.children().removeClass(checkedClass)

      # we can't use subviews_ here because we need the indices to line up correctly.
      for binding, idx in listView._mappedBindings.list when values.get_(idx) is selected
        binding.dom.addClass(checkedClass)
      return
    )
    return


module.exports = {
  EnumAttributeListEditView
  registerWith: (library) ->
    library.register(Enum, EnumAttributeListEditView, context: 'edit', style: 'list')
}


