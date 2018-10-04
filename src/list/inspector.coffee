{ Model, dēfault, bind, from, List } = require('janus')

class WrappedList extends Model.build(
  dēfault('type', 'List')

  bind('subtype', from('list')
    .map((list) -> list.constructor.name)
    .map((name) -> name if name? and (name not in [ 'List', '_Class' ])))

  bind('length', from('list').flatMap((list) -> list.watchLength()))
)
  constructor: (list) -> super({ list })
  _initialize: ->
    this.set('of.class', this.get('list').constructor.modelClass)
    this.set('of.name', this.get('of.class')?.name)

  @wrap: (list) -> new WrappedList(list)

module.exports = {
  WrappedList,
  registerWith: (library) -> library.register(List, WrappedList.wrap)
}

