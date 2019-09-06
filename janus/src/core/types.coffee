{ Case } = require('../core/case')

module.exports =
  from: Case.build('dynamic', 'get', 'attribute', 'varying', 'app', 'self', 'subject', 'vm')
  result: Case.build('init', 'pending', 'progress', 'complete': [ 'success', 'failure' ])
  validity: Case.build('valid', 'warning', 'error')
  operation: Case.build('read', 'mutate': [ 'create', 'update', 'delete' ])
  traversal: Case.build('recurse', 'delegate', 'defer', 'varying', 'value', 'nothing')

