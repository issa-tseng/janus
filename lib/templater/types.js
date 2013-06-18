(function() {
  var WithOptions, WithView, util;

  util = require('../util/util');

  WithOptions = (function() {
    function WithOptions(model, options) {
      this.model = model;
      this.options = options;
    }

    return WithOptions;

  })();

  WithView = (function() {
    function WithView(view) {
      this.view = view;
    }

    return WithView;

  })();

  util.extend(module.exports, {
    WithOptions: WithOptions,
    WithView: WithView
  });

}).call(this);
