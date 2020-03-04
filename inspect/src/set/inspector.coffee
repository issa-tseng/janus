{ Set, Model, bind, from, initial } = require('janus')

class SetInspector extends Model.build(
  initial('type', 'Set') # so the list entity view shows the right name
  bind('length', from('target').flatMap((set) -> set.length))
)
  isInspector: true

  constructor: (set, options) -> super({ target: set }, options)
  @inspect: (set) -> new SetInspector(set)

module.exports = {
  SetInspector,
  registerWith: (library) -> library.register(Set, SetInspector.inspect)
}

