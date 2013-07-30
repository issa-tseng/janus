(function() {
  var janus, util;

  util = require('./util/util');

  janus = {
    util: util,
    Base: require('./core/base').Base,
    Model: require('./model/model').Model,
    reference: require('./model/reference'),
    attribute: require('./model/attribute'),
    store: require('./model/store'),
    collection: require('./collection/collection'),
    View: require('./view/view').View,
    DomView: require('./view/dom-view').DomView,
    Templater: require('./templater/templater').Templater,
    templater: require('./templater/package'),
    Library: require('./library/library').Library,
    varying: require('./core/varying'),
    Chainer: require('./core/chain').Chainer,
    application: {
      App: require('./application/app').App,
      endpoint: require('./application/endpoint'),
      handler: require('./application/handler'),
      manifest: require('./application/manifest'),
      PageModel: require('./model/page-model').PageModel,
      PageView: require('./view/page-view').PageView,
      ListView: require('./view/collection/list').ListView,
      listEdit: require('./view/collection/list-edit')
    }
  };

  util.extend(module.exports, janus);

  /*
          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                  Version 2, December 2004
  
  Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
  
  Everyone is permitted to copy and distribute verbatim or modified
  copies of this license document, and changing it is allowed as long
  as the name is changed.
  
             DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
    TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
  
   0. You just DO WHAT THE FUCK YOU WANT TO.
  */


}).call(this);
