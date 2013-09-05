(function() {
  var App, Base, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Base = require('../core/base').Base;

  util = require('../util/util');

  App = (function(_super) {
    __extends(App, _super);

    function App(libraries) {
      this.libraries = libraries;
      App.__super__.constructor.call(this);
    }

    App.prototype._get = function(library) {
      var _this = this;
      return function(obj, options) {
        if (options == null) {
          options = {};
        }
        return library.get(obj, util.extendNew(options, {
          constructorOpts: util.extendNew(options.constructorOpts, {
            app: _this
          })
        }));
      };
    };

    App.prototype.getView = function(obj, options) {
      return this._get(this.libraries.views)(obj, options);
    };

    App.prototype.getStore = function(obj, options) {
      return this._get(this.libraries.stores)(obj, options);
    };

    App.prototype._withLibraries = function(ext) {
      var newApp;
      newApp = new App(util.extendNew(this.libraries, ext));
      this.emit('derived', newApp);
      return newApp;
    };

    App.prototype.withViewLibrary = function(viewLibrary) {
      return this._withLibraries({
        views: viewLibrary
      });
    };

    App.prototype.withStoreLibrary = function(storeLibrary) {
      return this._withLibraries({
        stores: storeLibrary
      });
    };

    return App;

  })(Base);

  util.extend(module.exports, {
    App: App
  });

}).call(this);
