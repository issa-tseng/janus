(function() {
  var App, util;

  util = require('../util/util');

  App = (function() {
    function App(libraries) {
      this.libraries = libraries;
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

    App.prototype.withViewLibrary = function(viewLibrary) {
      return new App(util.extendNew(this.libraries, {
        views: viewLibrary
      }));
    };

    App.prototype.withStoreLibrary = function(storeLibrary) {
      return new App(util.extendNew(this.libraries, {
        stores: storeLibrary
      }));
    };

    return App;

  })();

  util.extend(module.exports, {
    App: App
  });

}).call(this);
