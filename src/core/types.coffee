{ extend } = require('../util/util')
{ defcase } = require('../core/case')


types =
  from: defcase('dynamic', 'watch', 'attribute', 'varying', 'app', 'self')

  result: defcase('init', 'pending', 'progress', 'complete': [ 'success', 'failure' ])

  validity: defcase('valid', 'invalid': [ 'warning', 'error' ])

  operation: defcase('read', 'mutate': [ 'create', 'update', 'delete' ])

  traversal: defcase.withOptions({ arity: 2 })('recurse', 'delegate', 'defer', 'varying', 'value', 'nothing')


module.exports = types

