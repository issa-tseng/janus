{ extend } = require('../util/util')
{ defcase } = require('../core/case')


types =
  from: defcase('org.janusjs.core.from.default', 'dynamic', 'watch', 'attribute', 'varying', 'app', 'self')

  result: defcase('org.janusjs.util.result', 'init', 'pending', 'progress', 'complete': [ 'success', 'failure' ])

  validity: defcase('org.janusjs.model.validity', 'valid', 'invalid': [ 'warning', 'error' ])

  operation: defcase('org.janusjs.reference.operation', 'read', 'mutate': [ 'create', 'update', 'delete' ])

  traversal: defcase('org.janusjs.collection.traversal': { arity: 2 }, 'recurse', 'delegate', 'defer', 'varying', 'value', 'nothing')


module.exports = types

