# The **Templater** is the means by which markup is bound against Models in
# Janus. Each Templater takes a piece of markup it works against and allows
# configuration, then can take a set of data in exchange for a databound DOM
# fragment.

util = require('../util/util')

Binder = require('./binder').Binder

class Templater
  constructor: (@options = {}) ->
    this._binder = new Binder(this.dom())
    this._binding()

  data: (primary, aux) -> this._binder.data(primary, aux)

  dom: -> this.__dom ?= this._dom()
  _dom: ->

  markup: -> this.dom().get(0).outerHTML

  _binding: -> this._binder


util.extend(module.exports,
  Templater: Templater
)

