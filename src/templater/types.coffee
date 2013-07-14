
util = require('../util/util')

class WithAux
  constructor: (@primary, @aux = {}) ->

class WithOptions
  constructor: (@model, @options) ->

class WithView
  constructor: (@view) ->

util.extend(module.exports,
  WithAux: WithAux
  WithOptions: WithOptions
  WithView: WithView
)

