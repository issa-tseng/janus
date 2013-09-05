(function() {
  var Binder, Templater, util;

  util = require('../util/util');

  Binder = require('./binder').Binder;

  Templater = (function() {
    function Templater(options) {
      this.options = options != null ? options : {};
      if (this.options.dom != null) {
        this._dom$ = this.options.dom;
      }
      this._binder = new Binder(this._wrappedDom(), {
        app: this.options.app
      });
      this._binding();
    }

    Templater.prototype._binding = function() {
      return this._binder;
    };

    Templater.prototype.markup = function() {
      return this._wrappedDom().get(0).innerHTML;
    };

    Templater.prototype.data = function(primary, aux, shouldRender) {
      return this._binder.data(primary, aux, shouldRender);
    };

    Templater.prototype.dom = function() {
      return this._dom$ != null ? this._dom$ : this._dom$ = this._dom();
    };

    Templater.prototype._dom = function() {};

    Templater.prototype._wrappedDom = function() {
      return this._wrappedDom$ != null ? this._wrappedDom$ : this._wrappedDom$ = this.dom().wrap('<div/>').parent();
    };

    return Templater;

  })();

  util.extend(module.exports, {
    Templater: Templater
  });

}).call(this);
