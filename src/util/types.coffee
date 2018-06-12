{ extend } = require('./util')
{ defcase } = require('../core/case')


types =
  result: defcase('org.janusjs.util.result', 'init', 'pending', 'progress', 'complete': [ 'success', 'failure' ])
  error: defcase('org.janusjs.util.error', 'denied', 'not_authorized', 'not_found', 'invalid', 'internal')

  handling: defcase('org.janusjs.store.handling', 'handled', 'unhandled')
  operation: defcase('org.janusjs.store.operation', 'fetch', 'mutate': [ 'create', 'update', 'delete' ])

  traversal: defcase('org.janusjs.collection.traversal': { arity: 2 }, 'recurse', 'delegate', 'defer', 'varying', 'value', 'nothing')

  validity: defcase('org.janusjs.model.validity', 'valid', 'invalid': [ 'warning', 'error' ])


module.exports = types

