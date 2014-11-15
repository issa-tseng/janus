(function() {
  var Varying, foldBase, folds;

  Varying = require('../core/varying').Varying;

  foldBase = function(update) {
    return function(collection) {
      var result, watched;

      result = new Varying(null);
      watched = 0;
      collection.watchLength().reactNow(function(length) {
        var idx, _fn, _i;

        _fn = function(idx) {
          return collection.watchAt(idx).reactNow(function(value) {
            return result.setValue(update(value, idx, collection));
          });
        };
        for (idx = _i = watched; watched <= length ? _i < length : _i > length; idx = watched <= length ? ++_i : --_i) {
          _fn(idx);
        }
        return watched = length;
      });
      return result;
    };
  };

  folds = {
    any: foldBase(function(value, _, collection) {
      var existTrue, item, _i, _len, _ref;

      if (value !== true) {
        existTrue = false;
        _ref = collection.list;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          if (item === true) {
            existTrue = true;
            break;
          }
        }
        return existTrue;
      } else {
        return true;
      }
    }),
    find: foldBase(function(value, idx, collection) {
      var elem, _i, _len;

      if (value === true) {
        return collection.list[idx];
      } else {
        for (_i = 0, _len = collection.length; _i < _len; _i++) {
          elem = collection[_i];
          if (f(elem) === true) {
            return elem;
          }
        }
        return null;
      }
    }),
    min: function(collection) {
      var last, update;

      last = null;
      update = function(value, idx, collection) {
        var largest, x;

        return last = last === null ? value : value <= last ? value : (largest = null, [
          (function() {
            var _i, _len, _ref, _results;

            _ref = collection.list;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              x = _ref[_i];
              _results.push(largest = largest != null ? Math.min(largest, x) : x);
            }
            return _results;
          })()
        ], last = largest);
      };
      return foldBase(update)(collection);
    },
    max: function(collection) {
      var last, update;

      last = null;
      update = function(value, idx, collection) {
        var largest, x;

        return last = last === null ? value : value >= last ? value : (largest = null, [
          (function() {
            var _i, _len, _ref, _results;

            _ref = collection.list;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              x = _ref[_i];
              _results.push(largest = largest != null ? Math.max(largest, x) : x);
            }
            return _results;
          })()
        ], last = largest);
      };
      return foldBase(update)(collection);
    },
    sum: function(collection) {
      var last, update, values;

      values = [];
      last = 0;
      update = function(value, idx, collection) {
        var diff, _ref;

        diff = (value != null ? value : 0) - ((_ref = values[idx]) != null ? _ref : 0);
        values[idx] = value;
        return last += diff;
      };
      return foldBase(update)(collection);
    },
    join: function(collection, joiner) {
      return foldBase(function(_, _2, collection) {
        return collection.list.join(joiner);
      })(collection);
    },
    fold: function(collection, memo, f) {
      var intermediate, update;

      intermediate = [];
      intermediate[-1] = Varying.ly(memo);
      update = function(value, idx, collection) {
        var start, _i, _ref;

        start = Math.min(intermediate.length, idx);
        for (idx = _i = start, _ref = collection.list.length; start <= _ref ? _i < _ref : _i > _ref; idx = start <= _ref ? ++_i : --_i) {
          intermediate[idx] = intermediate[idx - 1].map(function(last) {
            return f(last, value);
          });
        }
        return intermediate[intermediate.length - 1];
      };
      return foldBase(update)(collection);
    },
    scanl: function(collection, memo, f) {
      var intermediate;

      intermediate = new (require('./list').List)();
      intermediate.add(Varying.ly(memo));
      collection.watchLength().reactNow(function(length) {
        var idx, intermediateLength, _i, _j, _results, _results1;

        intermediateLength = intermediate.list.length - 1;
        if (length > intermediateLength) {
          _results = [];
          for (idx = _i = intermediateLength; intermediateLength <= length ? _i < length : _i > length; idx = intermediateLength <= length ? ++_i : --_i) {
            _results.push((function(idx) {
              return intermediate.add(Varying.combine([intermediate.watchAt(idx), collection.watchAt(idx)], f));
            })(idx));
          }
          return _results;
        } else if (length > intermediateLength) {
          _results1 = [];
          for (idx = _j = length; length <= intermediateLength ? _j < intermediateLength : _j > intermediateLength; idx = length <= intermediateLength ? ++_j : --_j) {
            _results1.push(intermediate.removeAt(intermediateLength));
          }
          return _results1;
        }
      });
      return intermediate;
    },
    foldl: function(collection, memo, f) {
      return folds.scanl(collection, memo, f).watchAt(-1);
    }
  };

  module.exports = folds;

}).call(this);
