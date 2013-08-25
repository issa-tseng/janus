(function() {
  var type, util, _fn, _i, _len, _ref, _ref1,
    __slice = [].slice;

  util = {
    isArray: (_ref = Array.isArray) != null ? _ref : function(obj) {
      return toString.call(obj) === '[object Array]';
    },
    isNumber: function(obj) {
      return toString.call(obj) === '[object Number]' && !isNaN(obj);
    },
    isPlainObject: function(obj) {
      return (typeof obj === 'object') && (obj.constructor === Object);
    },
    isPrimitive: function(obj) {
      return util.isString(obj) || util.isNumber(obj) || util === true || util === false;
    },
    _uniqueId: 0,
    uniqueId: function() {
      return util._uniqueId++;
    },
    once: function(f) {
      var run;

      run = false;
      return function() {
        var args;

        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (run === true) {
          return;
        }
        run = true;
        return f.apply(null, args);
      };
    },
    foldLeft: function(value) {
      return function(arr, f) {
        var elem, _i, _len;

        for (_i = 0, _len = arr.length; _i < _len; _i++) {
          elem = arr[_i];
          value = f(value, elem);
        }
        return value;
      };
    },
    reduceLeft: function(arr, f) {
      return util.foldLeft(arr[0])(arr, f);
    },
    first: function(arr) {
      return arr[0];
    },
    last: function(arr) {
      return arr[arr.length - 1];
    },
    resplice: function(arr, pull, push) {
      var idx;

      idx = arr.indexOf(pull);
      if (idx < 0) {
        idx = arr.length;
      }
      return arr.splice.apply(arr, [idx, 1].concat(__slice.call(push)));
    },
    extend: function() {
      var dest, k, src, srcs, v, _i, _len;

      dest = arguments[0], srcs = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      for (_i = 0, _len = srcs.length; _i < _len; _i++) {
        src = srcs[_i];
        for (k in src) {
          v = src[k];
          dest[k] = v;
        }
      }
      return null;
    },
    extendNew: function() {
      var obj, srcs;

      srcs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      obj = {};
      util.extend.apply(util, [obj].concat(__slice.call(srcs)));
      return obj;
    },
    hasProperties: function(obj) {
      var k;

      for (k in obj) {
        if (obj.hasOwnProperty(k)) {
          return true;
        }
      }
      return false;
    },
    normalizePath: function(path) {
      if (path.length !== 1) {
        return path;
      } else {
        if (util.isString(path[0])) {
          return path[0].split('.');
        } else if (util.isArray(path[0])) {
          return path[0];
        }
      }
    },
    deepGet: function() {
      var idx, obj, path;

      obj = arguments[0], path = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      path = util.normalizePath(path);
      if (path == null) {
        return null;
      }
      idx = 0;
      while ((obj != null) && idx < path.length) {
        obj = obj[path[idx++]];
      }
      return obj != null ? obj : null;
    },
    deepSet: function() {
      var idx, obj, path, _name, _ref1;

      obj = arguments[0], path = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      path = util.normalizePath(path);
      if (path == null) {
        return null;
      }
      idx = 0;
      while ((idx + 1) < path.length) {
        obj = (_ref1 = obj[_name = path[idx++]]) != null ? _ref1 : obj[_name] = {};
      }
      return function(x) {
        if (util.isFunction(x)) {
          return x();
        } else {
          return obj[path[idx]] = x;
        }
      };
    },
    traverse: function(obj, f, path) {
      var k, subpath, v;

      if (path == null) {
        path = [];
      }
      for (k in obj) {
        v = obj[k];
        subpath = path.concat([k]);
        if ((v != null) && util.isPlainObject(v)) {
          util.traverse(v, f, subpath);
        } else {
          f(subpath, v);
        }
      }
      return obj;
    },
    traverseAll: function(obj, f, path) {
      var k, subpath, v;

      if (path == null) {
        path = [];
      }
      for (k in obj) {
        v = obj[k];
        subpath = path.concat([k]);
        f(subpath, v);
        if ((obj[k] != null) && util.isPlainObject(obj[k])) {
          util.traverseAll(obj[k], f, subpath);
        }
      }
      return obj;
    }
  };

  _ref1 = ['Arguments', 'Function', 'String', 'Date', 'RegExp'];
  _fn = function(type) {
    return util['is' + type] = function(obj) {
      return toString.call(obj) === ("[object " + type + "]");
    };
  };
  for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
    type = _ref1[_i];
    _fn(type);
  }

  if (typeof /./ !== 'function') {
    util.isFunction = function(obj) {
      return typeof obj === 'function';
    };
  }

  util.extend(module.exports, util);

}).call(this);
