
module.exports =
  view:
    list: require('./view/list')
    listEdit: require('./view/list-edit')
    literal: require('./view/literal')
    varying: require('./view/varying')

    registerWith: (library) -> view.registerWith(library) for _, view of this

