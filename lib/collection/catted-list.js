(function() {
  var CattedList, DerivedList, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  DerivedList = require('./list').DerivedList;

  util = require('../util/util');

  CattedList = (function(_super) {
    __extends(CattedList, _super);

    function CattedList(lists, options) {
      var list, listIdx, _fn, _i, _len, _ref,
        _this = this;

      this.lists = lists;
      this.options = options != null ? options : {};
      CattedList.__super__.constructor.call(this);
      this.list = util.foldLeft([])(this.lists, function(elems, list) {
        return elems.concat(list.list);
      });
      _ref = this.lists;
      _fn = function(list, listIdx) {
        var getOverallIdx;

        getOverallIdx = function(itemIdx) {
          return util.foldLeft(0)(_this.lists.slice(0, listIdx), function(length, list) {
            return length + list.list.length;
          }) + itemIdx;
        };
        list.on('added', function(elem, idx) {
          return _this._add(elem, getOverallIdx(idx));
        });
        return list.on('removed', function(_, idx) {
          return _this._removeAt(getOverallIdx(idx));
        });
      };
      for (listIdx = _i = 0, _len = _ref.length; _i < _len; listIdx = ++_i) {
        list = _ref[listIdx];
        _fn(list, listIdx);
      }
    }

    return CattedList;

  })(DerivedList);

  util.extend(module.exports, {
    CattedList: CattedList
  });

}).call(this);
