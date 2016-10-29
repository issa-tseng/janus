util = require('./util/util')

janus = (window ? global)._janus$ ?=
  util: util # life-saving util funcs

  Base: require('./core/base').Base

  Model: require('./model/model').Model
  reference: require('./model/reference')
  attribute: require('./model/attribute')
  Issue: require('./model/issue').Issue
  store: require('./model/store')

  collection: require('./collection/collection')

  View: require('./view/view').View
  DomView: require('./view/dom-view').DomView
  Templater: require('./templater/templater').Templater
  templater: require('./templater/package')

  Library: require('./library/library').Library
  varying: require('./core/varying')
  Chainer: require('./core/chain').Chainer

  application:
    App: require('./application/app').App
    endpoint: require('./application/endpoint')
    handler: require('./application/handler')
    manifest: require('./application/manifest')

    PageModel: require('./model/page-model').PageModel
    PageView: require('./view/page-view').PageView

    VaryingView: require('./view/impl/varying').VaryingView
    ListView: require('./view/impl/list').ListView
    listEdit: require('./view/impl/list-edit')

util.extend(module.exports, janus)
