{ inspect } = require('./inspect')

# export.
module.exports = {
  inspect,

  view:
    case:
      entity: require('./case/entity-view')
    common:
      textAttribute: require('./common/text-attribute')
    model:
      panel: require('./model/panel-view')
      entity: require('./model/entity-view')
    varying:
      entity: require('./varying/entity-view')

    registerWith: (library) ->
      for _, type of this when type isnt this.registerWith
        for _, view of type
          view.registerWith(library)
}

