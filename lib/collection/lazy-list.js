(function() {
  var CachedLazyList, Coverage, LazyList, List, Model, Range, Varying, rangeUpdater, util, wrapAndSealFate, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  _ref = require('../util/range'), Coverage = _ref.Coverage, Range = _ref.Range;

  List = require('./list').List;

  Model = require('../model/model').Model;

  Varying = require('../core/varying').Varying;

  wrapAndSealFate = function(range, f) {
    var wrapped;

    wrapped = new Range(range.lower, range.upper, range);
    wrapped.on('destroying', function() {
      return range.destroy();
    });
    return wrapped;
  };

  rangeUpdater = function(from, to) {
    return function() {
      if (from.value instanceof List) {
        return to.value.put(Math.max(from.lower - to.lower, 0), from.value.slice(Math.max(to.lower - from.lower, 0), +(from.upper - to.lower) + 1 || 9e9));
      }
    };
  };

  LazyList = (function(_super) {
    __extends(LazyList, _super);

    LazyList.bind('signature').fromVarying(function() {
      return this._signature();
    });

    function LazyList(attributes, options) {
      this.options = options;
      LazyList.__super__.constructor.call(this, attributes, this.options);
      this._activeRanges = new List();
      this._watchSignature();
    }

    LazyList.prototype._watchSignature = function() {
      var _this = this;

      return this.watch('signature').on('changed', function(key) {
        var range, _i, _len, _ref1, _results;

        _ref1 = _this._activeRanges.list;
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          range = _ref1[_i];
          _results.push(range.setValue(_this._range(range.lower, range.upper)));
        }
        return _results;
      });
    };

    LazyList.prototype.at = function(idx) {
      return this.range(idx, idx).map(function(result) {
        if (result instanceof List) {
          return result[0];
        } else {
          return result;
        }
      });
    };

    LazyList.prototype.range = function(lower, upper) {
      var inner, range;

      inner = this._range(lower, upper);
      range = new Range(lower, upper, inner);
      range.on('destroying', function() {
        return inner.destroy();
      });
      this._activeRanges.add(range);
      return range;
    };

    LazyList.prototype._range = function(lower, upper) {};

    LazyList.prototype.length = function() {
      return this.watch('length');
    };

    LazyList.prototype._signature = function() {
      return new Varying('');
    };

    return LazyList;

  })(Model);

  CachedLazyList = (function(_super) {
    __extends(CachedLazyList, _super);

    function CachedLazyList() {
      var _this = this;

      CachedLazyList.__super__.constructor.call(this);
      this._extCoverage = new Coverage();
      this._intCoverages = {};
      this._activeRanges.on('added', function(range) {
        return _this._extCoverages.add(range);
      });
      this._initSignature(this.get('signature'));
    }

    CachedLazyList.prototype._watchSignature = function() {
      return this.watch('signature').on('changed', function(signature) {
        var range, _i, _len, _ref1, _results;

        if (this._intCoverages[signature] != null) {
          _ref1 = this._activeRanges.list;
          _results = [];
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            range = _ref1[_i];
            _results.push(this._fetchRange(range));
          }
          return _results;
        } else {
          return this._initSignature(signature);
        }
      });
    };

    CachedLazyList.prototype._initSignature = function(signature) {
      var lower, range, upper, _i, _j, _len, _len1, _ref1, _ref2, _ref3;

      this._intCoverages[signature] = new Coverage();
      _ref1 = this._extCoverages.fills();
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        _ref2 = _ref1[_i], lower = _ref2[0], upper = _ref2[1];
        this.range(lower, upper);
      }
      _ref3 = this._activeRanges.list;
      for (_j = 0, _len1 = _ref3.length; _j < _len1; _j++) {
        range = _ref3[_j];
        range.setValue(this._fetchRange(new Range(range.lower, range.upper, new List())));
      }
      return null;
    };

    CachedLazyList.prototype.range = function(lower, upper) {
      var result, wrapped;

      result = new Range(lower, upper, new List());
      wrapped = wrapAndSealFate(result);
      this._fetchRange(result);
      this._activeRanges.add(wrapped);
      return wrapped;
    };

    CachedLazyList.prototype._fetchRange = function(result) {
      var gaps, intCoverage, lower, range, upper, _fn, _fn1, _i, _j, _len, _len1, _ref1, _ref2;

      intCoverage = this._intCoverage[this.get('signature')];
      _ref1 = intCoverage.within(lower, upper);
      _fn = function(range) {
        var update;

        update = rangeUpdater(range, result);
        update();
        return range.on('changed', update);
      };
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        range = _ref1[_i];
        _fn(range);
      }
      gaps = intCoverage.gaps(lower, upper);
      _fn1 = function() {
        var update;

        range = this._range(lower, upper);
        update = rangeUpdater(range, result);
        update();
        return range.on('changed', update);
      };
      for (_j = 0, _len1 = gaps.length; _j < _len1; _j++) {
        _ref2 = gaps[_j], lower = _ref2[0], upper = _ref2[1];
        _fn1();
      }
      return result;
    };

    return CachedLazyList;

  })(LazyList);

  util.extend(module.exports, {
    LazyList: LazyList,
    CachedLazyList: CachedLazyList
  });

}).call(this);
