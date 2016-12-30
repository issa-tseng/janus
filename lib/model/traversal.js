// Generated by CoffeeScript 1.12.2
(function() {
  var Traversal, cases, cases2, defcase, defer, delegate, extendNew, fn, from, get, identity, isFunction, isParentValueParent, k, kase, match, matcher, nothing, processNode, recurse, ref, ref1, ref2, value, varying, withContext, x,
    slice = [].slice;

  from = require('../core/from').from;

  ref = require('../core/case'), defcase = ref.defcase, match = ref.match;

  ref1 = require('../util/util'), identity = ref1.identity, isFunction = ref1.isFunction, extendNew = ref1.extendNew;

  withContext = function(name) {
    var obj1;
    return (
      obj1 = {},
      obj1["" + name] = {
        unapply: function(x, additional) {
          if (isFunction(x)) {
            return x.apply(null, [this.value[0], this.value[1]].concat(slice.call(additional)));
          } else {
            return x;
          }
        }
      },
      obj1
    );
  };

  cases = (ref2 = defcase.apply(null, ['org.janusjs.traversal'].concat(slice.call((function() {
    var i, len, ref2, results;
    ref2 = ['recurse', 'delegate', 'defer', 'varying', 'value', 'nothing'];
    results = [];
    for (i = 0, len = ref2.length; i < len; i++) {
      x = ref2[i];
      results.push(withContext(x));
    }
    return results;
  })()))), recurse = ref2.recurse, delegate = ref2.delegate, defer = ref2.defer, varying = ref2.varying, value = ref2.value, nothing = ref2.nothing, ref2);

  cases2 = {};

  fn = function(kase) {
    return cases2[k] = function(x, context) {
      return kase([x, context]);
    };
  };
  for (k in cases) {
    kase = cases[k];
    fn(kase);
  }

  get = function(obj, k) {
    if (obj.isCollection === true) {
      return obj.at(k);
    } else if (obj.isStruct === true) {
      return obj.get(k);
    }
  };

  isParentValueParent = function(obj, k, v) {
    if (obj._parent != null) {
      return get(obj._parent, k) === v._parent;
    } else {
      return false;
    }
  };

  matcher = match(recurse(function(into, context, local) {
    return local.root(into, local.map, context != null ? context : local.context, local.reduce);
  }), delegate(function(to, context, local) {
    return matcher(to(local.key, local.value, local.obj, local.attribute, context != null ? context : local.context), extendNew(local, {
      context: context
    }));
  }), defer(function(to, context, local) {
    return matcher(to(local.key, local.value, local.obj, local.attribute, context != null ? context : local.context), extendNew(local, {
      context: context,
      map: to
    }));
  }), varying(function(v, _, local) {
    var result;
    result = v.map(function(x) {
      return matcher(x, local);
    });
    if (local.immediate === true) {
      result = result.get();
    }
    return result;
  }), value(function(x) {
    return x;
  }), nothing(function() {
    return void 0;
  }));

  processNode = function(general) {
    return function(key, value) {
      var attribute, local, obj;
      obj = general.obj;
      if (obj.isModel === true && obj.isCollection !== true) {
        attribute = obj.attribute(key);
      }
      local = extendNew(general, {
        key: key,
        value: value,
        attribute: attribute
      });
      return matcher(general.map(key, value, obj, attribute, general.context), local);
    };
  };

  Traversal = {
    asNatural: function(obj, map, context) {
      var general;
      if (context == null) {
        context = {};
      }
      general = {
        obj: obj,
        map: map,
        context: context,
        root: Traversal.asNatural
      };
      if (obj.isCollection === true) {
        return obj.enumeration().flatMapPairs(processNode(general));
      } else {
        return typeof obj.flatMap === "function" ? obj.flatMap(processNode(general)) : void 0;
      }
    },
    asList: function(obj, map, context, reduce) {
      if (context == null) {
        context = {};
      }
      if (reduce == null) {
        reduce = identity;
      }
      return reduce(obj.enumeration().flatMapPairs(processNode({
        obj: obj,
        map: map,
        context: context,
        reduce: reduce,
        root: Traversal.asList
      })));
    },
    getArray: function(obj, map, context, reduce) {
      var attribute, key, local;
      if (context == null) {
        context = {};
      }
      if (reduce == null) {
        reduce = identity;
      }
      return reduce((function() {
        var i, len, ref3, results;
        ref3 = obj.enumerate();
        results = [];
        for (i = 0, len = ref3.length; i < len; i++) {
          key = ref3[i];
          value = get(obj, key);
          if (obj.isModel === true && obj.isCollection !== true) {
            attribute = obj.attribute(key);
          }
          local = {
            obj: obj,
            map: map,
            reduce: reduce,
            key: key,
            value: value,
            attribute: attribute,
            context: context,
            immediate: true,
            root: Traversal.getArray
          };
          results.push(matcher(map(key, value, obj, attribute, context), local));
        }
        return results;
      })());
    }
  };

  Traversal["default"] = {
    serialize: {
      map: function(obj, k, v, attribute, context) {
        if ((attribute != null ? attribute.serialize : void 0) != null) {
          return value(attribute.serialize());
        } else if (v != null) {
          if (v.isCollection === true || v.isStruct === true) {
            return recurse(v);
          } else {
            return value(v);
          }
        } else {
          return nothing();
        }
      }
    },
    modified: {
      map: function(obj, k, v, attribute, context) {
        if (obj._parent == null) {
          return value(false);
        } else if ((v != null ? v.isStruct : void 0) === true) {
          if (isParentValueParent(obj, k, v)) {
            return recurse(v);
          } else {
            return value(true);
          }
        } else if ((v != null ? v.isCollection : void 0) === true) {
          if (isParentValueParent(obj, k, v)) {
            return varying(from(v.watchLength()).and(v._parent.watchLength()).all.plain().map(function(la, lb) {
              if (la !== lb) {
                return value(true);
              } else {
                return recurse(v);
              }
            }));
          } else {
            return value(true);
          }
        } else if ((v != null ? v.isVarying : void 0) === true) {
          return varying(v.map(Traversal["default"].modified.map));
        } else {
          return value(obj._parent.get(k) !== v);
        }
      },
      reduce: function(list) {
        return list.any(function(x) {
          return x === true;
        });
      }
    },
    diff: {
      map: function(obj, k, va, attribute, arg) {
        var other, vb;
        other = arg.other;
        vb = other != null ? get(other, k) : null;
        if ((va == null) && (vb == null)) {
          return value(false);
        } else if ((va != null) && (vb != null)) {
          if (va.isCollection === true && vb.isCollection === true) {
            return varying(from(va.watchLength()).and(vb.watchLength()).all.plain().map(function(la, lb) {
              if (la !== lb) {
                return value(true);
              } else {
                return recurse(va, {
                  other: vb
                });
              }
            }));
          } else if (va.isStruct === true && vb.isStruct === true) {
            return varying(from(va.enumeration().watchLength()).and(vb.enumeration().watchLength()).all.plain().map(function(la, lb) {
              if (la !== lb) {
                return value(true);
              } else {
                return recurse(va, {
                  other: vb
                });
              }
            }));
          } else {
            return value(va === vb);
          }
        } else {
          return value(true);
        }
      },
      reduce: function(list) {
        return list.any(function(x) {
          return x === true;
        });
      }
    }
  };

  module.exports = {
    Traversal: Traversal,
    cases: cases2
  };

}).call(this);