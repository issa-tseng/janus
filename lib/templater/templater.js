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
        bindOnly: !!this.options.bindOnly
      });
      this._binding();
    }

    Templater.prototype._binding = function() {
      return this._binder;
    };

    Templater.prototype.markup = function() {
      return this._wrappedDom().get(0).innerHTML;
    };

    Templater.prototype.data = function(primary, aux) {
      return this._binder.data(primary, aux);
    };

    Templater.prototype.dom = function() {
      var _ref;

      return (_ref = this._dom$) != null ? _ref : this._dom$ = this._dom();
    };

    Templater.prototype._dom = function() {};

    Templater.prototype._wrappedDom = function() {
      var _ref;

      return (_ref = this._wrappedDom$) != null ? _ref : this._wrappedDom$ = this.dom().wrap('<div/>').parent();
    };

    return Templater;

  })();

  util.extend(module.exports, {
    Templater: Templater
  });

}).call(this);
