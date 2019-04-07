{ inspect } = require('./inspect')

# export.
module.exports = {
  inspect

  inspector:
    attribute: require('./attribute/inspector')
    case: require('./case/inspector')
    domview: require('./dom-view/inspector')
    function: require('./function/inspector')
    list: require('./list/inspector')
    literal: require('./literal/inspector')
    model: require('./model/inspector')
    varying: require('./varying/inspector')

  view:
    attribute:
      entity: require('./attribute/entity-view')
      panel: require('./attribute/panel-view')
    case:
      entity: require('./case/entity-view')
    common:
      linkedList: require('./common/linked-list')
      dataPair: require('./common/data-pair-view')
      textAttribute: require('./common/text-attribute')
    domview:
      panel: require('./dom-view/panel-view')
      entity: require('./dom-view/entity-view')
    function:
      panel: require('./function/panel-view')
      entity: require('./function/entity-view')
    list:
      panel: require('./list/panel-view')
      entity: require('./list/entity-view')

      filtered: require('./list/derived/filtered-list')
      mapped: require('./list/derived/mapped-list')
    literal:
      entity: require('./literal/entity-view')
      panel: require('./literal/panel-view')
    model:
      panel: require('./model/panel-view')
      entity: require('./model/entity-view')
    varying:
      panel: require('./varying/panel-view')
      entity: require('./varying/entity-view')

    registerWith: (library) ->
      for _, type of this when type isnt this.registerWith
        for _, view of type
          view.registerWith(library)
}

