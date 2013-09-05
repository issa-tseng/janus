(function() {
  var PartitionedList, UniqList, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  PartitionedList = require('./partitioned-list').PartitionedList;

  util = require('../util/util');

  UniqList = (function(_super) {
    __extends(UniqList, _super);

    function UniqList(lists, options) {
      var elems;
      this.lists = lists;
      this.options = options != null ? options : {};
      elems = util.foldLeft([])(this.lists, function(elems, list) {
        return elems.concat(list.list);
      });
      UniqList.__super__.constructor.call(this, elems);
    }

    return UniqList;

  })(PartitionedList);

  util.extend(module.exports, {
    UniqList: UniqList
  });

}).call(this);
