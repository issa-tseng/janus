{ inspect } = require('./inspect')

# export.
module.exports = {
  inspect,

  view:
    case:
      entity: require('./case/entity-view')
    common:
      linkedList: require('./common/linked-list')
      textAttribute: require('./common/text-attribute')
    list:
      entity: require('./list/entity-view')
    literal:
      entity: require('./literal/entity-view')
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

