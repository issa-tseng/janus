{ Model, dēfault, bind, from, List } = require('janus')

class ListInspector extends Model.build(
  dēfault('type', 'List')

  bind('derived', from('list').map((list) -> list.isDerivedList is true))
  bind('length', from('list').flatMap((list) -> list.length))
)
  isInspector: true

  constructor: (list) -> super({ list })
  _initialize: ->
    this.set('of.class', this.get_('list').constructor.modelClass)
    this.set('of.name', this.get_('of.class')?.name)

  @inspect: (list) ->
    if list.mapper?
      if list._bindings? then new ListInspector(list)
      else new ListInspector.Mapped(list)
    else if list.filterer? then new ListInspector.Filtered(list)
    else new ListInspector(list)

########################################
# DERIVED LIST TYPES

ListInspector.Mapped = class extends ListInspector.build(
  dēfault('type', 'MappedList'))

ListInspector.Filtered = class extends ListInspector.build(
  dēfault('type', 'FilteredList'))


module.exports = {
  ListInspector,
  registerWith: (library) -> library.register(List, ListInspector.inspect)
}

