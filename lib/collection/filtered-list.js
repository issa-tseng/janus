(function() {
  var DerivedList, FilteredList, Varying, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  DerivedList = require('./list').DerivedList;

  Varying = require('../core/varying').Varying;

  util = require('../util/util');

  FilteredList = (function(_super) {
    __extends(FilteredList, _super);

    function FilteredList(parent, isMember, options) {
      var _this = this;

      this.parent = parent;
      this.isMember = isMember;
      this.options = options != null ? options : {};
      FilteredList.__super__.constructor.call(this);
      this._filterers = [];
      this._idxMap = [];
      this._initElems(this.parent.list);
      this.parent.on('added', function(elem, idx) {
        return _this._initElems(elem, idx);
      });
      this.parent.on('removed', function(elem, idx) {
        var adjIdx, filterer, oldIdx, _i, _ref, _results;

        filterer = _this._filterers.splice(idx, 1)[0];
        oldIdx = _this._idxMap.splice(idx, 1)[0];
        if (filterer.value === true) {
          _this._removeAt(oldIdx);
          _results = [];
          for (adjIdx = _i = idx, _ref = _this._idxMap.length; idx <= _ref ? _i < _ref : _i > _ref; adjIdx = idx <= _ref ? ++_i : --_i) {
            _results.push(_this._idxMap[adjIdx] -= 1);
          }
          return _results;
        }
      });
    }

    FilteredList.prototype._initElems = function(elems, idx) {
      var elem, filterer, newFilterers, newMap, _, _fn, _i, _len,
        _this = this;

      if (idx == null) {
        idx = this.list.length;
      }
      if (!util.isArray(elems)) {
        elems = [elems];
      }
      newFilterers = (function() {
        var _i, _len, _results;

        _results = [];
        for (_i = 0, _len = elems.length; _i < _len; _i++) {
          elem = elems[_i];
          _results.push(Varying.ly(this.isMember(elem)));
        }
        return _results;
      }).call(this);
      newMap = (function() {
        var _i, _len, _ref, _results;

        _results = [];
        for (_i = 0, _len = elems.length; _i < _len; _i++) {
          _ = elems[_i];
          _results.push((_ref = this._idxMap[idx - 1]) != null ? _ref : -1);
        }
        return _results;
      }).call(this);
      Array.prototype.splice.apply(this._filterers, [idx, 0].concat(newFilterers));
      Array.prototype.splice.apply(this._idxMap, [idx, 0].concat(newMap));
      _fn = function(filterer) {
        var lastResult;

        lastResult = false;
        return filterer.reactNow(function(result) {
          var adjIdx, idxAdj, _j, _ref, _ref1;

          idx = _this._filterers.indexOf(filterer);
          if (idx === -1) {
            return;
          }
          result = result === true;
          if (result !== lastResult) {
            idxAdj = result === true ? 1 : -1;
            for (adjIdx = _j = idx, _ref = _this._idxMap.length; idx <= _ref ? _j < _ref : _j > _ref; adjIdx = idx <= _ref ? ++_j : --_j) {
              _this._idxMap[adjIdx] += idxAdj;
            }
            if (result === true) {
              _this._add(_this.parent.at(idx), (_ref1 = _this._idxMap[idx]) != null ? _ref1 : 0);
            } else {
              _this._removeAt(_this._idxMap[idx]);
            }
            return lastResult = result;
          }
        });
      };
      for (_i = 0, _len = newFilterers.length; _i < _len; _i++) {
        filterer = newFilterers[_i];
        _fn(filterer);
      }
      return null;
    };

    return FilteredList;

  })(DerivedList);

  util.extend(module.exports, {
    FilteredList: FilteredList
  });

}).call(this);
