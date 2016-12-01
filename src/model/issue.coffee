Base = require('../core/base').Base
Varying = require('../core/varying').Varying


class Issue extends Base
  constructor: ({ active, severity, message, target } = {}) ->
    this.active = Varying.ly(active ? false)
    this.severity = Varying.ly(severity ? 0)
    this.message = Varying.ly(message ? '')
    this.target = Varying.ly(target)


module.exports = { Issue }

