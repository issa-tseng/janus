
util = require('../util/util')

Chainer = (params...) ->
  class InnerChain
    constructor: (@parent, @key, @value) ->

    for param in params
      do (param) =>
        this.prototype[param] = (value) ->
          new InnerChain(this, param, value)

    all: (data = {}) ->
      data[this.key] = this.value if this.key? and this.value?
      this.parent.all(data)

    get: (key) -> if this.key is key then this.value else this.parent.get(key)

  class OuterChain extends InnerChain
    constructor: ->
    all: (data) -> data
    get: null


Chainer.augment = (proto) -> (params...) ->
  Chain = Chainer(params...)
  for param in params
    do (param) =>
      proto[param] = (value) ->
        this._chain = (this._chain ? new Chain())[param](value)
        this


util.extend(module.exports,
  Chainer: Chainer
)

