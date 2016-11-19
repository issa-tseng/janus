{ extend } = require('./util')
{ caseSet } = require('../core/case')

types =
  result: caseSet('org.janusjs.util.result', 'init', 'pending', 'progress', 'success', 'failure')
  error: caseSet('org.janusjs.util.error', 'denied', 'not_authorized', 'not_found', 'invalid', 'internal')

extend(module.exports, types)

