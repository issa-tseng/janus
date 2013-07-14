(function() {
  var util;

  util = require('../util/util');

  util.extend(module.exports, {
    WithAux: require('./types').WithAux,
    WithOptions: require('./types').WithOptions,
    WithView: require('./types').WithView,
    Templater: require('./templater').Templater
  });

}).call(this);
