
util = require('../util/util')

class WithOptions
  constructor: (@model, @options) ->

class WithView
  constructor: (@view) ->

util.extend(module.exports,
  WithOptions: WithOptions
  WithView: WithView
)

