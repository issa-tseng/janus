(function() {
  var DerivedList, List, PartitionedList, Varying, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  _ref = require('./list'), List = _ref.List, DerivedList = _ref.DerivedList;

  Varying = require('../core/varying').Varying;

  util = require('../util/util');

  PartitionedList = (function(_super) {
    __extends(PartitionedList, _super);

    function PartitionedList(parent, partitioner, options) {
      var elem, _i, _len, _ref1,
        _this = this;
      this.parent = parent;
      this.partitioner = partitioner;
      this.options = options != null ? options : {};
      PartitionedList.__super__.constructor.call(this);
      this._partitions = {};
      _ref1 = this.parent.list;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        elem = _ref1[_i];
        this._add(elem);
      }
      this.parent.on('added', function(elem, idx) {
        return _this._add(elem, idx);
      });
      this.parent.on('removed', function(_, idx) {
        return _this._removeAt(idx);
      });
    }

    PartitionedList.prototype._add = function(elem, idx) {};

    return PartitionedList;

  })(DerivedList);

  util.extend(module.exports, {
    PartitionedList: PartitionedList
  });

}).call(this);
