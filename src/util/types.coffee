{ extend } = require('./util')
{ caseSet } = require('../core/case')

types =
  result: caseSet('init', 'pending', 'progress', 'success', 'failure')
  error: caseSet('denied', 'not_authorized', 'not_found', 'invalid', 'internal')

extend(module.exports, types)

