(function() {
  var ComposedVarying, FlatMappedVarying, FlattenedVarying, MappedVarying, Varied, Varying, fix, isFunction, uniqueId, _ref, _ref1,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  _ref = require('../util/util'), isFunction = _ref.isFunction, fix = _ref.fix, uniqueId = _ref.uniqueId;

  Varying = (function() {
    Varying.prototype.isVarying = true;

    function Varying(value) {
      this.set(value);
      this._observers = {};
      this._generation = 0;
    }

    Varying.prototype.map = function(f) {
      return new MappedVarying(this, f);
    };

    Varying.prototype.flatten = function() {
      return new FlattenedVarying(this);
    };

    Varying.prototype.flatMap = function(f) {
      return new FlatMappedVarying(this, f);
    };

    Varying.prototype.react = function(f_) {
      var id,
        _this = this;

      id = uniqueId();
      return this._observers[id] = new Varied(id, f_, function() {
        return delete _this._observers[id];
      });
    };

    Varying.prototype.reactNow = function(f_) {
      var varied;

      varied = this.react(f_);
      f_.call(varied, this.get());
      return varied;
    };

    Varying.prototype.set = function(value) {
      var generation, observer, _, _ref1;

      if (value === this._value) {
        return;
      }
      generation = this._generation += 1;
      this._value = value;
      _ref1 = this._observers;
      for (_ in _ref1) {
        observer = _ref1[_];
        observer.f_(this._value);
        if (generation !== this._generation) {
          return;
        }
      }
      return null;
    };

    Varying.prototype.get = function() {
      return this._value;
    };

    Varying.pure = function() {
      var args, expected, f;

      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (util.isFunction(args[0])) {
        f = args[0];
        expected = f.length;
        return (fix(function(curry) {
          return function() {
            var args;

            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            if (args.length < expected) {
              return function() {
                var more;

                more = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
                return curry(args.concat(more));
              };
            } else {
              return new ComposedVarying(args, f);
            }
          };
        }))(args);
      } else {
        f = args.pop();
        return new ComposedVarying(args, f);
      }
    };

    Varying.mapAll = Varying.pure;

    Varying.ly = function(val) {
      if ((val != null ? val.isVarying : void 0) === true) {
        return val;
      } else {
        return new Varying(val);
      }
    };

    return Varying;

  })();

  Varied = (function() {
    function Varied(id, f_, stop) {
      this.id = id;
      this.f_ = f_;
      this.stop = stop;
    }

    return Varied;

  })();

  FlatMappedVarying = (function(_super) {
    var identity;

    __extends(FlatMappedVarying, _super);

    identity = function(x) {
      return x;
    };

    function FlatMappedVarying(_parent, _f, _flatten) {
      this._parent = _parent;
      this._f = _f != null ? _f : identity;
      this._flatten = _flatten != null ? _flatten : true;
      this._observers = {};
    }

    FlatMappedVarying.prototype.react = function(callback) {
      var id, lastInnerVaried, lastResult, onValue, parentVaried, self, varied,
        _this = this;

      self = this;
      id = uniqueId();
      this._observers[id] = varied = new Varied(id, callback, function() {
        delete _this._observers[id];
        return parentVaried.stop();
      });
      lastResult = null;
      lastInnerVaried = null;
      onValue = function(value) {
        var result;

        result = self._f.call(null, value);
        if (result === lastResult) {
          return;
        }
        if (self._flatten === true && this === parentVaried) {
          if (lastInnerVaried != null) {
            lastInnerVaried.stop();
          }
          if ((result != null ? result.isVarying : void 0) === true) {
            lastInnerVaried = result.reactNow(onValue);
            return;
          } else {
            lastInnerVaried = null;
          }
        }
        callback.call(varied, result);
        return lastResult = result;
      };
      parentVaried = this._parent.react(onValue);
      return varied;
    };

    FlatMappedVarying.prototype.set = null;

    FlatMappedVarying.prototype.get = function() {
      var value;

      if (this._flatten === true) {
        value = this._parent.get();
        if ((value != null ? value.isVarying : void 0) === true) {
          return this._f.call(null, value.get());
        } else {
          return this._f.call(null, value);
        }
      } else {
        return this._f.call(null, this._parent.get());
      }
    };

    return FlatMappedVarying;

  })(Varying);

  FlattenedVarying = (function(_super) {
    __extends(FlattenedVarying, _super);

    function FlattenedVarying(parent) {
      FlattenedVarying.__super__.constructor.call(this, parent, null);
    }

    return FlattenedVarying;

  })(FlatMappedVarying);

  MappedVarying = (function(_super) {
    __extends(MappedVarying, _super);

    function MappedVarying(parent, f) {
      MappedVarying.__super__.constructor.call(this, parent, f, false);
    }

    return MappedVarying;

  })(FlatMappedVarying);

  ComposedVarying = (function(_super) {
    __extends(ComposedVarying, _super);

    function ComposedVarying() {
      _ref1 = ComposedVarying.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    return ComposedVarying;

  })(FlatMappedVarying);

  module.exports = {
    Varying: Varying,
    Varied: Varied,
    FlatMappedVarying: FlatMappedVarying,
    FlattenedVarying: FlattenedVarying,
    MappedVarying: MappedVarying,
    ComposedVarying: ComposedVarying
  };

}).call(this);
