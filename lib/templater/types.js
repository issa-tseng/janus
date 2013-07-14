(function() {
  var WithAux, WithOptions, WithView, util;

  util = require('../util/util');

  WithAux = (function() {
    function WithAux(primary, aux) {
      this.primary = primary;
      this.aux = aux != null ? aux : {};
    }

    return WithAux;

  })();

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
    WithAux: WithAux,
    WithOptions: WithOptions,
    WithView: WithView
  });

}).call(this);
