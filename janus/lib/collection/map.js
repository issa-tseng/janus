// Generated by CoffeeScript 1.12.2
(function() {
  var DerivedMap, Enumerable, Map, Nothing, NothingClass, Varying, _changed, deepDelete, deepGet, deepSet, isArray, isEmptyObject, isPlainObject, isString, ref, traverse, traverseAll,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Enumerable = require('./collection').Enumerable;

  Varying = require('../core/varying').Varying;

  ref = require('../util/util'), deepGet = ref.deepGet, deepSet = ref.deepSet, deepDelete = ref.deepDelete, isArray = ref.isArray, isString = ref.isString, isPlainObject = ref.isPlainObject, isEmptyObject = ref.isEmptyObject, traverse = ref.traverse, traverseAll = ref.traverseAll;

  NothingClass = (function() {
    function NothingClass() {}

    return NothingClass;

  })();

  Nothing = new NothingClass();

  _changed = function(map, key, newValue, oldValue) {
    var ref1;
    if (oldValue === Nothing) {
      oldValue = null;
    }
    if (isPlainObject(oldValue) && (newValue == null)) {
      traverse(oldValue, (function(_this) {
        return function(path, value) {
          var ref1, subkey;
          subkey = key + "." + (path.join('.'));
          if ((ref1 = map._watches[subkey]) != null) {
            ref1.set(null);
          }
          return map.emit('changed', subkey, null, value);
        };
      })(this));
    }
    if ((ref1 = map._watches[key]) != null) {
      ref1.set(newValue);
    }
    map.emit('changed', key, newValue, oldValue);
  };

  Map = (function(superClass) {
    extend(Map, superClass);

    Map.prototype.isMap = true;

    function Map(data, options) {
      if (data == null) {
        data = {};
      }
      this.options = options != null ? options : {};
      Map.__super__.constructor.call(this);
      this.data = {};
      this._watches = {};
      if (this.options.parent != null) {
        this._parent = this.options.parent;
        this.listenTo(this._parent, 'changed', (function(_this) {
          return function(key, newValue, oldValue) {
            return _this._parentChanged(key, newValue, oldValue);
          };
        })(this));
      }
      if (typeof this._preinitialize === "function") {
        this._preinitialize();
      }
      this.set(data);
      if (typeof this._initialize === "function") {
        this._initialize();
      }
    }

    Map.prototype.get_ = function(key) {
      var value;
      value = deepGet(this.data, key);
      if ((value == null) && (this._parent != null)) {
        value = this._parent.get_(key);
        if ((value != null ? value.isEnumerable : void 0) === true) {
          value = value.shadow();
          this.set(key, value);
        }
      }
      if (value === Nothing) {
        return null;
      } else {
        return value;
      }
    };

    Map.prototype.set = function(x, y) {
      var obj, xIsString, yIsPlainObject;
      xIsString = isString(x);
      if (xIsString && (y === null)) {
        return this.unset(x);
      } else if (xIsString && arguments.length === 1) {
        return (function(_this) {
          return function(y) {
            return _this.set(x, y);
          };
        })(this);
      } else {
        yIsPlainObject = isPlainObject(y);
        if ((y != null) && (!yIsPlainObject || isEmptyObject(y))) {
          return this._set(x, y);
        } else if (yIsPlainObject) {
          obj = {};
          deepSet(obj, x)(y);
          return traverse(obj, (function(_this) {
            return function(path, value) {
              return _this._set(path, value);
            };
          })(this));
        } else if (isPlainObject(x)) {
          return traverse(x, (function(_this) {
            return function(path, value) {
              return _this._set(path, value);
            };
          })(this));
        }
      }
    };

    Map.prototype._set = function(key, value) {
      var oldValue;
      oldValue = deepGet(this.data, key);
      if (oldValue === value) {
        return;
      }
      deepSet(this.data, key)(value);
      if (isArray(key)) {
        key = key.join('.');
      }
      _changed(this, key, value, oldValue);
    };

    Map.prototype.unset = function(key) {
      var oldValue;
      if ((this._parent != null) && this.isDerivedMap !== true) {
        oldValue = this.get_(key);
        deepSet(this.data, key)(Nothing);
      } else {
        oldValue = deepDelete(this.data, key);
      }
      if (oldValue != null) {
        _changed(this, key, this.get_(key), oldValue);
      }
      return oldValue;
    };

    Map.prototype.revert = function(key) {
      var newValue, oldValue;
      if (this._parent == null) {
        return;
      }
      oldValue = deepDelete(this.data, key);
      newValue = this.get_(key);
      if (newValue !== oldValue) {
        _changed(this, key, newValue, oldValue);
      }
      return oldValue;
    };

    Map.prototype.shadow = function(klass) {
      return new (klass != null ? klass : this.constructor)({}, Object.assign({}, this.options, {
        parent: this
      }));
    };

    Map.prototype["with"] = function(data, klass) {
      return new (klass != null ? klass : this.constructor)(data, Object.assign({}, this.options, {
        parent: this
      }));
    };

    Map.prototype.original = function() {
      var ref1, ref2;
      return (ref1 = (ref2 = this._parent) != null ? ref2.original() : void 0) != null ? ref1 : this;
    };

    Map.prototype.get = function(key) {
      var extant, v;
      extant = this._watches[key];
      if (extant != null) {
        return extant;
      } else {
        v = new Varying(this.get_(key));
        v.__owner = this;
        return this._watches[key] = v;
      }
    };

    Map.prototype._parentChanged = function(key, newValue, oldValue) {
      var ourValue, ref1;
      ourValue = deepGet(this.data, key);
      if ((ourValue != null) || ourValue === Nothing) {
        return;
      }
      if ((ref1 = this._watches[key]) != null) {
        ref1.set(newValue);
      }
      this.emit('changed', key, newValue, oldValue);
    };

    Map.prototype.values_ = function() {
      var i, key, len, ref1, results;
      ref1 = this.enumerate_();
      results = [];
      for (i = 0, len = ref1.length; i < len; i++) {
        key = ref1[i];
        results.push(this.get_(key));
      }
      return results;
    };

    Map.prototype.values = function() {
      return this.enumerate().flatMap((function(_this) {
        return function(k) {
          return _this.get(k);
        };
      })(this));
    };

    Map.prototype.mapPairs = function(f) {
      var result;
      result = new DerivedMap(this, f);
      traverse(this.data, function(k, v) {
        k = k.join('.');
        return result.__set(k, f(k, v));
      });
      result.listenTo(this, 'changed', (function(_this) {
        return function(key, value) {
          if ((value != null) && value !== Nothing) {
            return result.__set(key, f(key, value));
          } else {
            return result._unset(key);
          }
        };
      })(this));
      return result;
    };

    Map.prototype.flatMapPairs = function(f) {
      var add, bindings, result;
      result = new DerivedMap(this, f);
      result._bindings = bindings = {};
      add = (function(_this) {
        return function(key) {
          return bindings[key] != null ? bindings[key] : bindings[key] = Varying.all([Varying.of(key), _this.get(key)]).flatMap(f).react(function(x) {
            return result.__set(key, x);
          });
        };
      })(this);
      traverse(this.data, function(k) {
        return add(k.join('.'));
      });
      result.listenTo(this, 'changed', (function(_this) {
        return function(key, newValue, oldValue) {
          var binding, k;
          if ((newValue != null) && (bindings[key] == null)) {
            return add(key);
          } else if ((oldValue != null) && (newValue == null)) {
            for (k in bindings) {
              binding = bindings[k];
              if (!(k.indexOf(key) === 0)) {
                continue;
              }
              binding.stop();
              delete bindings[k];
            }
            return result._unset(key);
          }
        };
      })(this));
      result.on('destroying', function() {
        var _, binding, results;
        results = [];
        for (_ in bindings) {
          binding = bindings[_];
          results.push(binding.stop());
        }
        return results;
      });
      return result;
    };

    Object.defineProperty(Map.prototype, 'length', {
      get: function() {
        return this.length$ != null ? this.length$ : this.length$ = Varying.managed(((function(_this) {
          return function() {
            return _this.enumerate();
          };
        })(this)), function(it) {
          return it.length;
        });
      }
    });

    Object.defineProperty(Map.prototype, 'length_', {
      get: function() {
        return this.enumerate_().length;
      }
    });

    Map.prototype.__destroy = function() {
      this._parent = null;
      return this._watches = Nothing;
    };

    Map.deserialize = function(data) {
      return new this(data);
    };

    return Map;

  })(Enumerable);

  DerivedMap = (function(superClass) {
    var i, len, method, ref1, roError;

    extend(DerivedMap, superClass);

    DerivedMap.prototype.isDerivedMap = true;

    function DerivedMap(_parent, _mapper) {
      this._parent = _parent;
      this._mapper = _mapper;
      DerivedMap.__super__.constructor.call(this);
    }

    roError = function() {
      throw new Error('this map is read-only');
    };

    ref1 = ['_set', 'setAll', 'unset', 'revert'];
    for (i = 0, len = ref1.length; i < len; i++) {
      method = ref1[i];
      DerivedMap.prototype["_" + method] = DerivedMap.__super__[method];
      DerivedMap.prototype[method] = roError;
    }

    DerivedMap.prototype.set = function() {
      return roError;
    };

    DerivedMap.prototype.shadow = function() {
      return this;
    };

    return DerivedMap;

  })(Map);

  module.exports = {
    Map: Map,
    Nothing: Nothing
  };

}).call(this);
