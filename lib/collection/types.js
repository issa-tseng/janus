(function() {
  var Collection, Model, OrderedCollection, util, _ref, _ref1,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  Model = require('../model/model').Model;

  util = require('../util/util');

  Collection = (function(_super) {
    __extends(Collection, _super);

    function Collection() {
      _ref = Collection.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Collection.prototype.filter = function(f) {
      return new (require('./filtered-list').FilteredList)(this, f);
    };

    Collection.prototype.map = function(f) {
      return new (require('./mapped-list').MappedList)(this, f);
    };

    Collection.prototype.concat = function() {
      var lists;

      lists = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (util.isArray(lists[0]) && lists.length === 1) {
        lists = lists[0];
      }
      return new (require('./catted-list').CattedList)([this].concat(lists));
    };

    Collection.prototype.partition = function(f) {
      return new (require('./partitioned-list').PartitionedList)(this, f);
    };

    Collection.prototype.uniq = function(f) {
      return new (require('./uniq-list').UniqList)(this, f);
    };

    return Collection;

  })(Model);

  OrderedCollection = (function(_super) {
    __extends(OrderedCollection, _super);

    function OrderedCollection() {
      _ref1 = OrderedCollection.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    return OrderedCollection;

  })(Collection);

  util.extend(module.exports, {
    Collection: Collection,
    OrderedCollection: OrderedCollection
  });

}).call(this);
