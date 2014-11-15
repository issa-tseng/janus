(function() {
  var Base, Binder, MultiVarying, Varying, fallbackMap, util, _ref,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  Base = require('../core/base');

  _ref = require('../core/varying'), Varying = _ref.Varying, MultiVarying = _ref.MultiVarying;

  fallbackMap = function() {
    var values;

    values = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    if (values.length === 1) {
      return values[0];
    } else {
      return values;
    }
  };

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
              return result != null ? result.watch(path[idx]).map(next(idx + 1)) : void 0;
            } else {
              return result != null ? result.watch(path[idx]) : void 0;
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

    Binder.prototype.fromSelf = function() {
      this._generators.push(function() {
        return new Varying(this._model);
      });
      return this;
    };

    Binder.prototype.and = Binder.prototype.from;

    Binder.prototype.andVarying = Binder.prototype.fromVarying;

    Binder.prototype.andSelf = Binder.prototype.fromSelf;

    Binder.prototype.flatMap = function(f) {
      this._flatMap = f;
      return this;
    };

    Binder.prototype.fallback = function(fallback) {
      this._fallback = fallback;
      return this;
    };

    Binder.prototype.asDefault = function() {
      this._defaultOnly = true;
      return this;
    };

    Binder.prototype.bind = function(model) {
      var bound;

      bound = Object.create(this);
      bound._model = model;
      if (this._defaultOnly === true && (model.get(this._key) != null)) {
        return;
      }
      bound.apply();
      return bound;
    };

    Binder.prototype.apply = function() {
      var data, _ref1, _ref2,
        _this = this;

      if ((_ref1 = this._varying) != null) {
        _ref1.destroy();
      }
      return this._varying = new MultiVarying((function() {
        var _i, _len, _ref2, _results;

        _ref2 = this._generators;
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          data = _ref2[_i];
          _results.push(data.call(this));
        }
        return _results;
      }).call(this), (_ref2 = this._flatMap) != null ? _ref2 : fallbackMap).map(function(result) {
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
