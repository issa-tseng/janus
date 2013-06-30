(function() {
  var Chainer, util,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  Chainer = function() {
    var InnerChain, OuterChain, params;

    params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    InnerChain = (function() {
      var param, _fn, _i, _len,
        _this = this;

      function InnerChain(parent, key, value) {
        this.parent = parent;
        this.key = key;
        this.value = value;
      }

      _fn = function(param) {
        return InnerChain.prototype[param] = function(value) {
          return new InnerChain(this, param, value);
        };
      };
      for (_i = 0, _len = params.length; _i < _len; _i++) {
        param = params[_i];
        _fn(param);
      }

      InnerChain.prototype.all = function(data) {
        if (data == null) {
          data = {};
        }
        if ((this.key != null) && (this.value != null)) {
          data[this.key] = this.value;
        }
        return this.parent.all(data);
      };

      InnerChain.prototype.get = function(key) {
        if (this.key === key) {
          return this.value;
        } else {
          return this.parent.get(key);
        }
      };

      return InnerChain;

    }).call(this);
    return OuterChain = (function(_super) {
      __extends(OuterChain, _super);

      function OuterChain() {}

      OuterChain.prototype.all = function(data) {
        return data;
      };

      OuterChain.prototype.get = null;

      return OuterChain;

    })(InnerChain);
  };

  Chainer.augment = function(proto) {
    return function() {
      var Chain, param, params, _i, _len, _results,
        _this = this;

      params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      Chain = Chainer.apply(null, params);
      _results = [];
      for (_i = 0, _len = params.length; _i < _len; _i++) {
        param = params[_i];
        _results.push((function(param) {
          return proto[param] = function(value) {
            var _ref;

            this._chain = ((_ref = this._chain) != null ? _ref : new Chain())[param](value);
            return this;
          };
        })(param));
      }
      return _results;
    };
  };

  util.extend(module.exports, {
    Chainer: Chainer
  });

}).call(this);
