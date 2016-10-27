(function() {
  var capitalize, caseSet, extendNew, isFunction, isPlainObject, match, otherwise, unapply, _ref,
    __slice = [].slice;

  _ref = require('../util/util'), extendNew = _ref.extendNew, capitalize = _ref.capitalize, isPlainObject = _ref.isPlainObject, isFunction = _ref.isFunction;

  otherwise = function(value) {
    var instance;

    instance = new String('otherwise');
    instance.value = value;
    instance["case"] = otherwise;
    return instance;
  };

  otherwise.type = 'otherwise';

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

  unapply = function(target, handler, unapply) {
    if (unapply == null) {
      unapply = true;
    }
    if (isFunction(handler)) {
      if (isFunction(target != null ? target.unapply : void 0) && unapply === true) {
        return target != null ? target.unapply(handler) : void 0;
      } else {
        return handler(target);
      }
    } else {
      return handler;
    }
  };

  match = function() {
    var args, first, hasOtherwise, i, kase, seen, set, x, _ref1, _ref2;

    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    first = args[0];
    set = (_ref1 = (_ref2 = first != null ? first["case"] : void 0) != null ? _ref2 : first) != null ? _ref1.set : void 0;
    seen = {};
    hasOtherwise = false;
    i = 0;
    while (i < args.length) {
      x = args[i];
      kase = x["case"] != null ? x["case"] : x;
      if (kase.type === 'otherwise') {
        hasOtherwise = true;
      } else {
        if (set[kase.type] == null) {
          throw new Error("found a case of some other set!");
        }
        seen[kase.type] = true;
      }
      i += x["case"] != null ? 1 : 2;
    }
    if (hasOtherwise === false) {
      for (kase in set) {
        if (seen[kase] !== true) {
          throw new Error('not all cases covered!');
        }
      }
    }
    return function(target) {
      var handler, _ref3, _ref4;

      i = 0;
      while (i < args.length) {
        x = args[i];
        if (x["case"] != null) {
          kase = x["case"];
          handler = x.value;
        } else {
          kase = args[i];
          handler = args[i + 1];
        }
        if (kase.type === 'otherwise') {
          return unapply(target, handler, false);
        }
        if (kase.type.valueOf() === (target != null ? target.valueOf() : void 0) && ((_ref3 = (_ref4 = target != null ? target["case"] : void 0) != null ? _ref4 : target) != null ? _ref3.set : void 0) === set) {
          return unapply(target, handler);
        }
        i += x["case"] != null ? 1 : 2;
      }
    };
  };

  module.exports = {
    caseSet: caseSet,
    match: match,
    otherwise: otherwise
  };

}).call(this);
