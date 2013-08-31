(function() {
  var Base, MultiVarying, Varying, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Base = require('../core/base').Base;

  util = require('../util/util');

  Varying = (function(_super) {
    __extends(Varying, _super);

    function Varying(value) {
      Varying.__super__.constructor.call(this);
      this.setValue(value);
    }

    Varying.prototype.setValue = function(value, force) {
      var _this = this;

      if (value === this) {
        value = null;
      } else if (value instanceof Varying) {
        if (this._childVarying != null) {
          this.unlistenTo(this._childVarying);
        }
        this._childVarying = value;
        value = this._childVarying.value;
        this.listenTo(this._childVarying, 'changed', function(newValue) {
          return _this._doSetValue(newValue, true);
        });
      }
      return this._doSetValue(value, force);
    };

    Varying.prototype.map = function(f) {
      var result,
        _this = this;

      result = new Varying(f(this.value));
      result.listenTo(this, 'changed', function(value) {
        return result.setValue(f(value));
      });
      result._parent = this;
      result._mapper = f;
      return result;
    };

    Varying.prototype.trace = function(name) {
      if (name == null) {
        name = this._id;
      }
      this.on('changed', function(value) {
        console.log("Varying " + name + " changed:");
        return console.log(value);
      });
      return this;
    };

    Varying.prototype.debug = function() {
      this.on('changed', function(value) {
        debugger;
      });
      return this;
    };

    Varying.prototype._doSetValue = function(value, force) {
      var oldValue;

      if (force == null) {
        force = false;
      }
      oldValue = this.value;
      if (force === true || value !== oldValue) {
        this.value = value;
        this.emit('changed', value, oldValue);
      }
      return value;
    };

    Varying.combine = function(varyings, transform) {
      return new MultiVarying(varyings, transform);
    };

    Varying.ly = function(val) {
      if (val instanceof Varying) {
        return val;
      } else {
        return new Varying(val);
      }
    };

    Varying.lie = {
      sticky: function(source, delays) {
        var lookup, result, timer;

        result = new Varying(source.value);
        result._parent = source;
        lookup = util.isFunction(delays) ? function(x) {
          return delays(x);
        } : function(x) {
          return delays[x];
        };
        timer = null;
        source.on('changed', function(newValue) {
          var delay;

          if (timer != null) {
            return;
          }
          delay = lookup(result.value);
          if (delay != null) {
            clearTimeout(timer);
            return timer = setTimeout((function() {
              timer = null;
              return result.setValue(source.value);
            }), delay);
          } else {
            return result.setValue(newValue);
          }
        });
        return result;
      }
    };

    return Varying;

  })(Base);

  MultiVarying = (function(_super) {
    __extends(MultiVarying, _super);

    function MultiVarying(varyings, flatMap) {
      var i, varying, _fn, _i, _len, _ref,
        _this = this;

      this.varyings = varyings != null ? varyings : [];
      this.flatMap = flatMap;
      MultiVarying.__super__.constructor.call(this);
      this.values = [];
      _ref = this.varyings;
      _fn = function(varying, i) {
        _this.values[i] = varying.value;
        return varying.on('changed', function(value) {
          _this.values[i] = value;
          return _this.update();
        });
      };
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        varying = _ref[i];
        _fn(varying, i);
      }
      this.update();
    }

    MultiVarying.prototype.update = function() {
      var value;

      value = this.values;
      if (this.flatMap != null) {
        value = this.flatMap.apply(this, value);
      }
      return this.setValue(value);
    };

    return MultiVarying;

  })(Varying);

  util.extend(module.exports, {
    Varying: Varying,
    MultiVarying: MultiVarying
  });

}).call(this);
