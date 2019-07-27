dollar = require('./dollar')

cache = null
module.exports = ($) ->
  dollar.set($)
  return cache ?= {
    list: require('./list')
    listEdit: require('./list-edit')
    literal: require('./literal')
    varying: require('./varying')
    textAttribute: require('./text-attribute')
    booleanAttribute: require('./boolean-attribute')
    numberAttribute: require('./number-attribute')
    enumAttribute: require('./enum-attribute')
    enumAttributeList: require('./enum-attribute-list')
    types: require('./types')

    registerWith: (library) ->
      view.registerWith(library) for _, view of this when view isnt this.registerWith
      return
  }

