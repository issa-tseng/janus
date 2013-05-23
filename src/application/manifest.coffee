
util = require('../util/util')
Base = require('../core/base').Base

class Manifest extends Base
  constructor: ->
    super()

    this._requestCount = 0
    this._objects = []

    this._setHook()

  requested: (request) ->
    this._requestCount += 1

    request.on 'complete', (result) =>
      this._objects.push(result)
      this._setHook()

  _setHook: ->
    # prevent multiple sets per loop
    return if this._hookSet is true
    this._hookSet = true

    setTimeout(( =>
      this._hookSet = false
      this.emit('allComplete') if this._requestCount is 0
    ), 0)

class StoreManifest extends Manifest
  constructor: (@library) ->
    super()

    this.listenTo this.library, 'got', (store) =>
      store.on 'requesting', (request) =>
        this.requested(request)


util.extend(module.exports,
  Manifest: Manifest
  StoreManifest: StoreManifest
)

