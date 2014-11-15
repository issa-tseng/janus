
util = require('../util/util')
Base = require('../core/base')
{ Varying, MultiVarying } = require('../core/varying')

fallbackMap = (values...) ->
  if values.length is 1
    values[0]
  else
    values

# TODO: Shares enough DNA with Templater Binder to be combined probably.
class Binder extends Base
  constructor: (key) ->
    this._key = key
    this._generators = []

  from: (path...) ->
    this._generators.push ->
      next = (idx) -> (result) ->
        if path[idx + 1]?
          result?.watch(path[idx]).map(next(idx + 1))
        else
          result?.watch(path[idx])

      next(0)(this._model)

    this

  fromVarying: (f) ->
    this._generators.push(-> f.call(this._model))
    this

  fromSelf: ->
    this._generators.push(-> new Varying(this._model))
    this

  and: this.prototype.from
  andVarying: this.prototype.fromVarying
  andSelf: this.prototype.fromSelf

  flatMap: (f) ->
    this._flatMap = f
    this

  fallback: (fallback) ->
    this._fallback = fallback
    this

  asDefault: ->
    this._defaultOnly = true
    this

  bind: (model) ->
    bound = Object.create(this)
    bound._model = model

    return if this._defaultOnly is true and model.get(this._key)?

    bound.apply()
    bound

  apply: ->
    this._varying?.destroy()

    this._varying = new MultiVarying((data.call(this) for data in this._generators), this._flatMap ? fallbackMap).map (result) =>
      result ?= this._fallback
      this._model.set(this._key, result)

util.extend(module.exports,
  Binder: Binder
)

