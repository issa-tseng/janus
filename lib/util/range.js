(function() {
  var Continuous, Coverage, Range, Varying, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('./util');

  Varying = require('../core/varying').Varying;

  Coverage = (function() {
    function Coverage(children) {
      var child, _i, _len;

      if (children == null) {
        children = [];
      }
      this.children = [];
      for (_i = 0, _len = children.length; _i < _len; _i++) {
        child = children[_i];
        this["with"](child);
      }
    }

    Coverage.prototype._with = function(range) {
      var idx, _ref, _ref1,
        _this = this;

      while ((idx = this._searchOverlap(range)) != null) {
        range = this.children.splice(idx, 1)._with(range);
      }
      this.children.push(range);
      this.lower = Math.min((_ref = this.lower) != null ? _ref : range.lower, range.lower);
      this.upper = Math.max((_ref1 = this.upper) != null ? _ref1 : range.upper, range.upper);
      range.on('split', function(newCoverage) {
        idx = _this.children.indexOf(range);
        if (idx < 0) {
          return range.destroy();
        } else {
          return _this.children[idx] = newCoverage;
        }
      });
      return this;
    };

    Coverage.prototype.add = Coverage.prototype._with;

    Coverage.prototype.overlaps = function(lower, upper) {
      return (lower <= this.upper) && (upper >= this.lower);
    };

    Coverage.prototype.within = function(lower, upper) {
      if (lower == null) {
        lower = this.lower;
      }
      if (upper == null) {
        upper = this.upper;
      }
      return util.foldLeft([])(this.children, function(result, child) {
        return result.concat(!child.overlaps(lower, upper) ? [] : child instanceof Range ? [child] : child.within(idx, length));
      });
    };

    Coverage.prototype.gaps = function(lower, upper) {
      var child, gaps, _i, _len, _ref;

      if (lower == null) {
        lower = this.lower;
      }
      if (upper == null) {
        upper = this.upper;
      }
      this.children.sort(function(a, b) {
        return a.lower - b.lower;
      });
      gaps = [];
      _ref = this.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        if (lower < child.lower) {
          gaps.push([lower, child.lower - 1]);
          lower = child.lower;
        }
        if (lower < child.upper) {
          if ((child instanceof Range) || (child instanceof Continuous)) {
            lower = child.upper + 1;
          } else {
            gaps = gaps.concat(child.gaps(lower, upper));
            lower = child.upper + 1;
          }
        }
        if (lower >= upper) {
          break;
        }
      }
      if (lower < upper) {
        gaps.push([lower, upper]);
      }
      return gaps;
    };

    Coverage.prototype.fills = function(lower, upper) {
      if (lower == null) {
        lower = this.lower;
      }
      if (upper == null) {
        upper = this.upper;
      }
      return util.foldLeft([])(this.children, function(result, child) {
        return result.concat(!child.overlaps(lower, upper) ? [] : (child instanceof Continuous) || (child instanceof Range) ? [child.lower, child.upper] : child.fills(lower, upper));
      });
    };

    Coverage.prototype._searchOverlap = function(range) {
      var child, idx, _i, _len, _ref;

      _ref = this.children;
      for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
        child = _ref[idx];
        if (child.overlaps(range.lower, range.upper)) {
          return idx;
        }
      }
      return null;
    };

    return Coverage;

  })();

  Continuous = (function(_super) {
    __extends(Continuous, _super);

    function Continuous(children) {
      var child, range, _fn, _i, _len, _ref,
        _this = this;

      this.children = children != null ? children : [];
      this.lower = util.reduceLeft((function() {
        var _i, _len, _ref, _results;

        _ref = this.children;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          _results.push(child.lower);
        }
        return _results;
      }).call(this), Math.min);
      this.upper = util.reduceLeft((function() {
        var _i, _len, _ref, _results;

        _ref = this.children;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          _results.push(child.upper);
        }
        return _results;
      }).call(this), Math.max);
      _ref = this.children;
      _fn = function(range) {
        return range.on('destroying', function() {
          return _this.emit('split', _this._without(range));
        });
      };
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        range = _ref[_i];
        _fn(range);
      }
    }

    Continuous.prototype._with = function(range) {
      return new Continuous(this.children.concat[range]);
    };

    Continuous.prototype._without = function(deadRange) {
      var range;

      return new Coverage((function() {
        var _i, _len, _ref, _results;

        _ref = this.children;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          range = _ref[_i];
          if (range !== deadRange) {
            _results.push(range);
          }
        }
        return _results;
      }).call(this));
    };

    return Continuous;

  })(Coverage);

  Range = (function(_super) {
    __extends(Range, _super);

    function Range(lower, upper, value) {
      this.lower = lower;
      this.upper = upper;
      Range.__super__.constructor.call(this, {
        value: value
      });
    }

    Range.prototype.overlaps = function(lower, upper) {
      return (lower <= this.upper) && (upper >= this.lower);
    };

    Range.prototype._with = function(other) {
      return new Continuous([this, other]);
    };

    Range.prototype.map = function(f) {
      var result,
        _this = this;

      result = new Range(this.lower, this.upper, this.value);
      this.on('changed', function(value) {
        return result.setValue(value);
      });
      return result;
    };

    return Range;

  })(Varying);

  util.extend(module.exports, {
    Coverage: Coverage,
    Continuous: Continuous,
    Range: Range
  });

}).call(this);
