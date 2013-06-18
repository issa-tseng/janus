(function() {
  var Model, OrderedIncrementalList, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Model = require('../model/model').Model;

  util = require('../util/util');

  OrderedIncrementalList = (function(_super) {
    __extends(OrderedIncrementalList, _super);

    function OrderedIncrementalList() {
      _ref = OrderedIncrementalList.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    return OrderedIncrementalList;

  })(Model);

  util.extend(module.exports, {
    OrderedIncrementalList: OrderedIncrementalList
  });

}).call(this);
