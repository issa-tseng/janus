# The **Templater** is the means by which markup is bound against Models in
# Janus. Each Templater takes a piece of markup it works against and allows
# configuration, then can take a set of data in exchange for a databound DOM
# fragment.

util = require('../util/util')
$ ?= require('zepto-node')

Binder = require('./binder')

class Templater
  constructor: (@markup) ->
    this.dom = $(this.markup)
    this._binder = this._binding()

  data: (primary, data) -> this._binder.data(primary, data)

  _binding: -> new Binder(this.dom)

