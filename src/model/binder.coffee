
util = require('../util/util')
Base = require('../core/base')
MultiVarying = require('../core/varying').MultiVarying

# TODO: Shares enough DNA with Templater Binder to be combined probably.
class Binder extends Base
  constructor: (key) ->
    this._key = key
    this._data = []

  from: (path...) ->
    this._data.push(path)
    this

  and: this.prototype.from

  transform: (transform) ->
    this._transform = transform
    this

  fallback: (fallback) ->
    this._fallback = fallback
    this

  to: (key) ->
    this._key = key
    this

  bind: (model) ->
    bound = Object.create(this)
    bound._model = model

    bound.apply()
    null

  apply: ->
    return if this._applied is true
    this._applied = true

    this._varyings =
      for path in this._data
        next = (idx) -> (result) ->
          if path[idx + 1]?
            result?.watch(path[idx], next(idx + 1))
          else
            result?.watch(path[idx])

        next(0)(this._model)

    this._varying = new MultiVarying this._varyings, (values...) =>
      result =
        if util.isFunction(this._transform)
          this._transform(values...)
        else
          if values.length is 1
            values[0]
          else
            values

      result ?= this._fallback

      this._model.set(this._key, result)

util.extend(module.exports,
  Binder: Binder
)

