
util = require('../util/util')
Base = require('../core/base').Base

Request = require('../model/store').Request

class Manifest extends Base
  constructor: ->
    super()

    this._requestCount = 0
    this.requests = []
    this.objects = []

    this._setHook()

  requested: (request) ->
    this._requestCount += 1

    this.requests.push(request)
    this.emit('requestStart', request)

    handleChange = (state) =>
      if state instanceof Request.state.type.Complete
        this.objects.push(state.result) if state instanceof Request.state.type.Success

        this.emit('requestComplete', request, state.result)

        this._requestCount -= 1
        this._setHook()

    request.on('changed', handleChange)
    handleChange(request.value)

    null

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
      store.on('requesting', (request) => this.requested(request))


util.extend(module.exports,
  Manifest: Manifest
  StoreManifest: StoreManifest
)

