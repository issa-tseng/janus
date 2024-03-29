// Generated by CoffeeScript 1.12.2
(function() {
  var Traversal, Varying, curry2, deepSet, defer, delegate, fix, identity, isFunction, listRoot, match, naturalRoot, nothing, otherwise, pair, recurse, ref, ref1, ref2, root, value, varying;

  Varying = require('../core/varying').Varying;

  ref = require('../util/util'), identity = ref.identity, isFunction = ref.isFunction, deepSet = ref.deepSet, fix = ref.fix, curry2 = ref.curry2;

  ref1 = require('../core/case'), match = ref1.match, otherwise = ref1.otherwise;

  ref2 = require('../core/types').traversal, recurse = ref2.recurse, delegate = ref2.delegate, defer = ref2.defer, varying = ref2.varying, value = ref2.value, nothing = ref2.nothing;

  pair = function(recurser, fs, obj, immediate) {
    return function(key, val) {
      var attribute;
      if (obj.isModel === true) {
        attribute = obj.attribute(key);
      }
      return fix(function(recontext) {
        return function(fs) {
          return fix(function(rematch) {
            return match(recurse(function(into) {
              return recurser(fs, into);
            }), delegate(function(to) {
              return rematch(to(key, val, obj, attribute));
            }), defer(function(to) {
              return recontext(Object.assign({}, fs, to));
            }), varying(function(v) {
              if (immediate === true) {
                return rematch(v.get());
              } else {
                return v.map(rematch);
              }
            }), value(function(x) {
              return x;
            }), nothing(function() {
              return void 0;
            }));
          })(fs.map(key, val, obj, attribute));
        };
      })(fs);
    };
  };

  root = function(traverse) {
    return function(recurser, fs, obj) {
      var ref3;
      return fix(function(rematch) {
        return match(recurse(function(into) {
          return traverse(recurser, fs, into);
        }), delegate(function(to) {
          return rematch(to(obj));
        }), defer(function(to) {
          return root(traverse)(Object.assign({}, fs, to), recurser, obj);
        }), varying(function(v) {
          return v.flatMap(rematch);
        }), value(function(x) {
          return x;
        }), nothing(function() {
          return void 0;
        }));
      })(((ref3 = fs.recurse) != null ? ref3 : recurse)(obj));
    };
  };

  naturalRoot = root(function(recurser, fs, obj) {
    return obj.flatMapPairs(pair(recurser, fs, obj));
  });

  listRoot = root(function(recurser, fs, obj) {
    if (fs.reduce != null) {
      return Varying.managed((function() {
        return obj.enumerate().flatMapPairs(pair(recurser, fs, obj));
      }), fs.reduce);
    } else {
      return obj.enumerate().flatMapPairs(pair(recurser, fs, obj));
    }
  });

  Traversal = {
    natural: curry2(function(fs, obj) {
      return naturalRoot(Traversal.natural, fs, obj);
    }),
    list: curry2(function(fs, obj) {
      return listRoot(Traversal.list, fs, obj);
    }),
    natural_: curry2(function(fs, obj) {
      var i, j, key, len, len1, lpair, ref3, ref4, result, results;
      lpair = pair(Traversal.natural_, fs, obj, true);
      if (obj.isMappable === true) {
        ref3 = obj.enumerate_();
        results = [];
        for (i = 0, len = ref3.length; i < len; i++) {
          key = ref3[i];
          results.push(lpair(key, obj.get_(key)));
        }
        return results;
      } else {
        result = {};
        ref4 = obj.enumerate_();
        for (j = 0, len1 = ref4.length; j < len1; j++) {
          key = ref4[j];
          deepSet(result, key)(lpair(key, obj.get_(key)));
        }
        return result;
      }
    }),
    list_: curry2(function(fs, obj) {
      var i, key, len, lpair, ref3, results;
      lpair = pair(Traversal.list_, fs, obj, true);
      ref3 = obj.enumerate_();
      results = [];
      for (i = 0, len = ref3.length; i < len; i++) {
        key = ref3[i];
        results.push(lpair(key, obj.get_(key)));
      }
      return results;
    })
  };

  Traversal["default"] = {
    serialize: {
      map: function(k, v, _, attribute) {
        if (attribute != null) {
          return value(attribute.serialize());
        } else if (v != null) {
          if (typeof v.serialize === 'function') {
            return value(v.serialize());
          } else if (v.isEnumerable === true) {
            return recurse(v);
          } else {
            return value(v);
          }
        } else {
          return nothing;
        }
      }
    },
    diff: {
      recurse: function(arg) {
        var oa, ob;
        oa = arg[0], ob = arg[1];
        if (((oa != null ? oa.isEnumerable : void 0) === true && (ob != null ? ob.isEnumerable : void 0) === true) && (oa.isMappable === ob.isMappable)) {
          return varying(Varying.mapAll(oa.length, ob.length, function(la, lb) {
            if (la !== lb) {
              return value(true);
            } else {
              return recurse(oa.flatMapPairs(function(k, va) {
                return ob.get(k).map(function(vb) {
                  return [va, vb];
                });
              }));
            }
          }));
        } else {
          return value(new Varying(oa !== ob));
        }
      },
      map: function(k, arg) {
        var va, vb;
        va = arg[0], vb = arg[1];
        if (((va != null ? va.isEnumerable : void 0) === true && (vb != null ? vb.isEnumerable : void 0) === true) && (va.isMappable === vb.isMappable)) {
          return recurse([va, vb]);
        } else {
          return value(va !== vb);
        }
      },
      reduce: function(list) {
        return list.any();
      }
    }
  };

  module.exports = {
    Traversal: Traversal
  };

}).call(this);
