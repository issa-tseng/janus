Base = require('../core/base').Base
Varying = require('../core/varying').Varying
util = require('../util/util')

class Issue extends Base
  constructor: ({ active, severity, message, target } = {}) ->
    this.active = Varying.ly(active ? false)
    this.severity = Varying.ly(severity ? 0)
    this.message = Varying.ly(message ? '')
    this.target = Varying.ly(target)

util.extend(module.exports,
  Issue: Issue
)

