{ Model, dēfault, bind, from, List } = require('janus')

class ListInspector extends Model.build(
  dēfault('type', 'List')

  bind('subtype', from('list')
    .map((list) -> list.constructor.name)
    .map((name) -> name if name? and (name not in [ 'List', '_Class' ])))

  bind('derived', from('list').map((list) -> list.isDerivedList is true))
  bind('length', from('list').flatMap((list) -> list.length))
)
  isInspector: true

  constructor: (list) -> super({ list })
  _initialize: ->
    this.set('of.class', this.get_('list').constructor.modelClass)
    this.set('of.name', this.get_('of.class')?.name)

  @inspect: (list) -> new ListInspector(list)

module.exports = {
  ListInspector,
  registerWith: (library) -> library.register(List, ListInspector.inspect)
}

