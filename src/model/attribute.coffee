
util = require('../util/util')

# Extraordinarily thin class just for wrapping schemas in a way that we can
# reference easily via `Library` without polluting `Object`. If I find a reason
# for Attributes to do anything more I will gladly expand them to be proper
# implementations (probably based on `Model`), but so far all cases I can find,
# the state it would encapsulate is better served living upon the `Model`
# itself.
class Attribute
  constructor: (@schema, @model, @key) ->

util.extend(module.exports,
  Attribute: Attribute
)

