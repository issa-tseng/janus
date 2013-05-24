# The **Templater** is the means by which markup is bound against Models in
# Janus. Each Templater takes a piece of markup it works against and allows
# configuration, then can take a set of data in exchange for a databound DOM
# fragment.

util = require('../util/util')

Binder = require('./binder').Binder

class Templater
  constructor: (@options = {}) ->
    this.__dom = this.options.dom if this.options.dom?

    this._binder = new Binder(this._wrappedDom(), { bindOnly: !!this.options.bindOnly })
    this._binding()

  data: (primary, aux) -> this._binder.data(primary, aux)

  dom: -> this.__dom ?= this._dom()
  _dom: ->

  _wrappedDom: -> this.__wrappedDom ?= this.dom().wrap('<div/>').parent()

  markup: -> this._wrappedDom().get(0).innerHTML

  _binding: -> this._binder


util.extend(module.exports,
  Templater: Templater
)

