
module.exports =
  view:
    list: require('./view/list')
    listEdit: require('./view/list-edit')
    literal: require('./view/literal')
    varying: require('./view/varying')
    textAttribute: require('./view/text-attribute')
    booleanAttribute: require('./view/boolean-attribute')
    numberAttribute: require('./view/number-attribute')
    enumAttribute: require('./view/enum-attribute')
    enumAttributeList: require('./view/enum-attribute-list')
    types: require('./view/types')

    registerWith: (library) -> view.registerWith(library) for _, view of this when view isnt this.registerWith

