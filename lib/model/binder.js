(function() {
  var Base, Binder, MultiVarying, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  util = require('../util/util');

  Base = require('../core/base');

  MultiVarying = require('../core/varying').MultiVarying;

  Binder = (function(_super) {
    __extends(Binder, _super);

    function Binder(key) {
      this._key = key;
      this._generators = [];
    }

    Binder.prototype.from = function() {
      var path;

      path = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this._generators.push(function() {
        var next;

        next = function(idx) {
          return function(result) {
            if (path[idx + 1] != null) {
              return result != null ? typeof result.watch === "function" ? result.watch(path[idx], next(idx + 1)) : void 0 : void 0;
            } else {
              return result != null ? typeof result.watch === "function" ? result.watch(path[idx]) : void 0 : void 0;
            }
          };
        };
        return next(0)(this._model);
      });
      return this;
    };

    Binder.prototype.fromVarying = function(f) {
      this._generators.push(function() {
        return f.call(this._model);
      });
      return this;
    };

    Binder.prototype.and = Binder.prototype.from;

    Binder.prototype.andVarying = Binder.prototype.fromVarying;

    Binder.prototype.flatMap = function(f) {
      this._flatMap = f;
      return this;
    };

    Binder.prototype.fallback = function(fallback) {
      this._fallback = fallback;
      return this;
    };

    Binder.prototype.bind = function(model) {
      var bound;

      bound = Object.create(this);
      bound._model = model;
      bound.apply();
      return null;
    };

    Binder.prototype.apply = function() {
      var data,
        _this = this;

      if (this._applied === true) {
        return;
      }
      this._applied = true;
      return this._varying = new MultiVarying((function() {
        var _i, _len, _ref, _results;

        _ref = this._generators;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          data = _ref[_i];
          _results.push(data.call(this));
        }
        return _results;
      }).call(this), function() {
        var result, values;

        values = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        result = util.isFunction(_this._flatMap) ? _this._flatMap.apply(_this._model, values) : values.length === 1 ? values[0] : values;
        if (result == null) {
          result = _this._fallback;
        }
        return _this._model.set(_this._key, result);
      });
    };

    return Binder;

  })(Base);

  util.extend(module.exports, {
    Binder: Binder
  });

}).call(this);
