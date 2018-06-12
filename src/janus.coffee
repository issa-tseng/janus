util = require('./util/util')

# pre-require these to fan them out top-level:
kase = require('./core/case')
template = require('./view/template')
collection = require('./collection/collection')

# integrate these bits into one object:
schema = require('./model/schema')
attribute = schema.attribute
util.extend(attribute, require('./model/attribute'))

# TODO: once we're sure the global is superfluous, remove.
module.exports = (window ? global)._janus$ ?=
  # core functionality.
  Varying: require('./core/varying').Varying
  defcase: kase.defcase
  match: kase.match
  otherwise: kase.otherwise
  from: require('./core/from')

  # collection functionality.
  Base: require('./core/base').Base

  Map: require('./collection/map').Map
  List: require('./collection/list').List
  Set: require('./collection/set').Set

  Traversal: require('./collection/traversal').Traversal

  Enumerable: collection.Enumerable
  Collection: collection.Collection
  OrderedCollection: collection.OrderedCollection

  # model functionality.
  Model: require('./model/model').Model
  attribute: attribute
  bind: schema.bind
  issue: schema.issue
  transient: schema.transient
  default: schema.default
  Trait: schema.Trait
  store: require('./model/store')

  # view and templating functionality.
  View: require('./view/view').View
  DomView: require('./view/dom-view').DomView
  find: template.find
  template: template.template
  mutators: require('./view/mutators')

  # application stuff is nested to reduce clutter.
  application:
    App: require('./application/app').App
    Library: require('./application/library').Library
    endpoint: require('./application/endpoint')
    handler: require('./application/handler')
    manifest: require('./application/manifest')

  # maybe folks could use these.
  util: util
  types: require('./util/types')

