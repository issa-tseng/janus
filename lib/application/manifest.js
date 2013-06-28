(function() {
  var Base, Manifest, Request, StoreManifest, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  Base = require('../core/base').Base;

  Request = require('../model/store').Request;

  Manifest = (function(_super) {
    __extends(Manifest, _super);

    function Manifest() {
      Manifest.__super__.constructor.call(this);
      this._requestCount = 0;
      this._objects = [];
      this._setHook();
    }

    Manifest.prototype.requested = function(request) {
      var _this = this;

      this._requestCount += 1;
      return request.on('changed', function(state) {
        if (state instanceof Request.state.type.Complete) {
          if (state instanceof Request.state.type.Success) {
            _this._objects.push(state.result);
          }
          _this._requestCount -= 1;
          return _this._setHook();
        }
      });
    };

    Manifest.prototype._setHook = function() {
      var _this = this;

      if (this._hookSet === true) {
        return;
      }
      this._hookSet = true;
      return setTimeout((function() {
        _this._hookSet = false;
        if (_this._requestCount === 0) {
          return _this.emit('allComplete');
        }
      }), 0);
    };

    return Manifest;

  })(Base);

  StoreManifest = (function(_super) {
    __extends(StoreManifest, _super);

    function StoreManifest(library) {
      var _this = this;

      this.library = library;
      StoreManifest.__super__.constructor.call(this);
      this.listenTo(this.library, 'got', function(store) {
        return store.on('requesting', function(request) {
          return _this.requested(request);
        });
      });
    }

    return StoreManifest;

  })(Manifest);

  util.extend(module.exports, {
    Manifest: Manifest,
    StoreManifest: StoreManifest
  });

}).call(this);
