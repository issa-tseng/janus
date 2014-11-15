(function() {
  var capitalize, caseSet, extendNew, isFunction, isPlainObject, match, otherwise, unapply, _ref,
    __slice = [].slice;

  _ref = require('../util/util'), extendNew = _ref.extendNew, capitalize = _ref.capitalize, isPlainObject = _ref.isPlainObject, isFunction = _ref.isFunction;

  otherwise = 'otherwise';

  caseSet = function() {
    var caseProps, inTypes, k, set, type, types, v, _fn, _i, _len;

    inTypes = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    set = {};
    types = {};
    for (_i = 0, _len = inTypes.length; _i < _len; _i++) {
      type = inTypes[_i];
      if (isPlainObject(type)) {
        for (k in type) {
          v = type[k];
          types[k] = v;
        }
      } else {
        types[type] = {};
      }
    }
    _fn = function(type, caseProps) {
      var kase, props;

      props = {
        map: function(f) {
          return kase(f(this.value));
        },
        unapply: function(x) {
          if (isFunction(x)) {
            return x(this.value);
          } else {
            return x;
          }
        },
        toString: function() {
          return "" + this + ": " + this.value;
        }
      };
      kase = function(value) {
        var fType, instance, prop, val, _fn1, _ref1;

        instance = new String('' + type);
        instance.value = value;
        _fn1 = function(fType) {
          instance[fType + 'OrElse'] = function(x) {
            if (type === fType) {
              return this.value;
            } else {
              return x;
            }
          };
          return instance['flat' + capitalize(fType)] = function() {
            if (type === fType) {
              return this.value;
            } else {
              return this;
            }
          };
        };
        for (fType in types) {
          _fn1(fType);
        }
        instance["case"] = kase;
        _ref1 = extendNew(props, caseProps);
        for (prop in _ref1) {
          val = _ref1[prop];
          instance[prop] = val;
        }
        return instance;
      };
      kase.type = type;
      kase.set = set;
      return set[type] = kase;
    };
    for (type in types) {
      caseProps = types[type];
      _fn(type, caseProps);
    }
    return set;
  };

  unapply = function(target, handler) {
    if (isFunction(handler)) {
      return target != null ? target.unapply(handler) : void 0;
    } else {
      return handler;
    }
  };

  match = function() {
    var args, i, kase, seen, set, _i, _ref1, _ref2;

    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    set = (_ref1 = args[0]) != null ? _ref1.set : void 0;
    seen = {};
    otherwise = false;
    for (i = _i = 0, _ref2 = args.length; _i <= _ref2; i = _i += 2) {
      if (!(args[i] != null)) {
        continue;
      }
      kase = args[i];
      if (kase === 'otherwise') {
        otherwise = true;
      } else {
        if (set[kase.type] == null) {
          throw new Error("found a case of some other set!");
        }
        seen[kase.type] = true;
      }
    }
    if (otherwise === false) {
      for (kase in set) {
        if (seen[kase] !== true) {
          throw new Error('not all cases covered!');
        }
      }
    }
    return function(target) {
      var handler, _j, _ref3;

      for (i = _j = 0, _ref3 = args.length; _j <= _ref3; i = _j += 2) {
        kase = args[i];
        handler = args[i + 1];
        if (kase === 'otherwise') {
          return unapply(target, handler);
        }
        if (kase.type.valueOf() === (target != null ? target.valueOf() : void 0)) {
          return unapply(target, handler);
        }
      }
    };
  };

  module.exports = {
    caseSet: caseSet,
    match: match,
    otherwise: otherwise
  };

}).call(this);
