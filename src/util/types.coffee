{ extend } = require('./util')
{ defcase } = require('../core/case')

types =
  result: defcase('org.janusjs.util.result', 'init', 'pending', 'progress', 'success', 'failure')
  error: defcase('org.janusjs.util.error', 'denied', 'not_authorized', 'not_found', 'invalid', 'internal')

extend(module.exports, types)

