types = require('../util/types')
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
      if types.result.success.match(state) or types.result.failure.match(state)
        types.result.success.match(state, (x) => this.objects.push(x))

        this.emit('requestComplete', request, state.value)

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
  constructor: (@app) ->
    super()

    this.listenTo(this.app, 'vended', (type, store) =>
      store.on('requesting', (request) => this.requested(request)) if type is 'stores'
    )


module.exports = { Manifest, StoreManifest }

