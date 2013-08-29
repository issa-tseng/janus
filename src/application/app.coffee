Base = require('../core/base').Base
util = require('../util/util')


class App extends Base
  constructor: (@libraries) ->
    super()

  _get: (library) -> (obj, options = {}) =>
    library.get(obj, util.extendNew(options, { constructorOpts: util.extendNew(options.constructorOpts, { app: this }) }))

  getView: (obj, options) -> this._get(this.libraries.views)(obj, options)
  getStore: (obj, options) -> this._get(this.libraries.stores)(obj, options)

  _withLibraries: (ext) ->
    newApp = new App(util.extendNew(this.libraries, ext))
    this.emit('derived', newApp)
    newApp

  withViewLibrary: (viewLibrary) -> this._withLibraries({ views: viewLibrary })
  withStoreLibrary: (storeLibrary) -> this._withLibraries({ stores: storeLibrary })


util.extend(module.exports,
  App: App
)

