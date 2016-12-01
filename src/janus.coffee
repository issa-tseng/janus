util = require('./util/util')

# pre-require these to fan them out top-level
kase = require('./core/case')
template = require('./view/template')

# TODO: once we're sure the global is superfluous, remove.
module.exports = (window ? global)._janus$ ?=
  # core functionality.
  Varying: require('./core/varying').Varying
  defcase: kase.defcase
  match: kase.match
  otherwise: kase.otherwise
  from: require('./core/from')

  # model functionality.
  Base: require('./core/base').Base
  Model: require('./model/model').Model
  attribute: require('./model/attribute')
  Issue: require('./model/issue').Issue
  store: require('./model/store')

  # collection functionality.
  List: require('./collection/list').List
  Set: require('./collection/set').Set
  collection: require('./collection/types')

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

