{ extend } = require('./util')
{ caseSet } = require('../core/case')

types =
  result: caseSet('init', 'pending', 'progress', 'success', 'failure')

extend(module.exports, types)

