{ extend } = require('../util/util')
{ Case } = require('../core/case')


types =
  from: Case.build('dynamic', 'watch', 'attribute', 'varying', 'app', 'self')

  result: Case.build('init', 'pending', 'progress', 'complete': [ 'success', 'failure' ])

  validity: Case.build('valid', 'invalid': [ 'warning', 'error' ])

  operation: Case.build('read', 'mutate': [ 'create', 'update', 'delete' ])

  traversal: Case.withOptions({ arity: 2 }).build('recurse', 'delegate', 'defer', 'varying', 'value', 'nothing')


module.exports = types

