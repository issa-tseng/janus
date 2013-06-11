
util = require('../util/util')


class App
  constructor: (@libraries) ->

  _get: (library) -> (obj, options = {}) =>
    library.get(obj, util.extendNew(options, { constructorOpts: util.extendNew(options.constructorOpts, { app: this }) }))

  getView: (obj, options) -> this._get(this.libraries.views)(obj, options)
  getStore: (obj, options) -> this._get(this.libraries.stores)(obj, options)

  withViewLibrary: (viewLibrary) -> new App(util.extendNew(this.libraries, { views: viewLibrary }))
  withStoreLibrary: (storeLibrary) -> new App(util.extendNew(this.libraries, { stores: storeLibrary }))


util.extend(module.exports,
  App: App
)

