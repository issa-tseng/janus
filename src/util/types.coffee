{ extend } = require('./util')
{ caseSet } = require('../core/case')

types =
  result: caseSet('org.janus.util.result', 'init', 'pending', 'progress', 'success', 'failure')
  error: caseSet('org.janus.util.error', 'denied', 'not_authorized', 'not_found', 'invalid', 'internal')

extend(module.exports, types)

