Model = require('../model/model').Model
util = require('../util/util')


class App extends Model
  _get: (library) -> (obj, options = {}) =>
    library.get(obj, util.extendNew(options, { constructorOpts: util.extendNew(options.constructorOpts, { app: this }) }))

  getView: (obj, options) -> this._get(this.get('views'))(obj, options)
  getStore: (obj, options) -> this._get(this.get('stores'))(obj, options)

  withViewLibrary: (viewLibrary) ->
    result = this.shadow()
    result.set('views', viewLibrary)

    this.emit('derived', result)

    result

  withStoreLibrary: (storeLibrary) ->
    result = this.shadow()
    result.set('stores', storeLibrary)

    this.emit('derived', result)

    result

  resolve: (key) -> super(key, this)


module.exports = { App }

