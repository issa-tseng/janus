
module.exports =
  view:
    literal: require('./view/literal')
    varying: require('./view/varying')

    registerWith: (library) -> view.registerWith(library) for _, view of this

