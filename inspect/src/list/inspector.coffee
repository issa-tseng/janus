{ Model, initial, bind, from, List } = require('janus')

class ListInspector extends Model.build(
  initial('type', 'List')

  bind('derived', from('target').map((list) -> list.isDerivedList is true))
  bind('length', from('target').flatMap((list) -> list.length))
)
  isInspector: true

  constructor: (list) -> super({ target: list })
  _initialize: ->
    this.set('of.class', this.get_('target').constructor.modelClass)
    this.set('of.name', this.get_('of.class')?.name)

  @inspect: (list) ->
    if list.mapper?
      if list._bindings? then new ListInspector.FlatMapped(list)
      else new ListInspector.Mapped(list)
    else if list.filterer? then new ListInspector.Filtered(list)
    else new ListInspector(list)

########################################
# DERIVED LIST TYPES

ListInspector.Mapped = class extends ListInspector.build(
  initial('type', 'MappedList'))

ListInspector.FlatMapped = class extends ListInspector.build(
  initial('type', 'FlatMappedList'))

ListInspector.Filtered = class extends ListInspector.build(
  initial('type', 'FilteredList'))


module.exports = {
  ListInspector,
  registerWith: (library) -> library.register(List, ListInspector.inspect)
}

