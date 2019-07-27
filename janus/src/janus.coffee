util = require('./util/util')

# pre-require these to fan them out top-level:
kase = require('./core/case')
template = require('./view/template')
collection = require('./collection/collection')
resolver = require('./model/resolver')

# integrate these bits into one object:
schema = require('./model/schema')
attribute = schema.attribute
util.extend(attribute, require('./model/attribute'))

# TODO: once we're sure the global is superfluous, remove.
module.exports =
  # core functionality.
  Varying: require('./core/varying').Varying
  Case: kase.Case
  match: kase.match
  otherwise: kase.otherwise
  from: require('./core/from')
  types: require('./core/types')

  # collection functionality.
  Base: require('./core/base').Base

  Map: require('./collection/map').Map
  List: require('./collection/list').List
  Set: require('./collection/set').Set

  Traversal: require('./collection/traversal').Traversal

  # model functionality.
  Model: require('./model/model').Model
  Trait: schema.Trait

  attribute: attribute
  bind: schema.bind
  validate: schema.validate
  transient: schema.transient
  initial: schema.initial

  Request: resolver.Request
  Resolver: resolver.Resolver

  # view and templating functionality.
  View: require('./view/view').View
  DomView: require('./view/dom-view').DomView
  find: template.find
  template: template.template
  mutators: require('./view/mutators')

  # application classes.
  App: require('./application/app').App
  Library: require('./application/library').Library
  Manifest: require('./application/manifest').Manifest

  # maybe folks could use these.
  util: util

