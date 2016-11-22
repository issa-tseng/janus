
module.exports =
  view:
    list: require('./view/list')
    listEdit: require('./view/list-edit')
    literal: require('./view/literal')
    varying: require('./view/varying')
    textAttribute: require('./view/text-attribute')
    booleanAttribute: require('./view/boolean-attribute')
    numberAttribute: require('./view/number-attribute')

    registerWith: (library) -> view.registerWith(library) for _, view of this

