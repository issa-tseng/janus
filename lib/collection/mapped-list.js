(function() {
  var DerivedList, List, MappedList, Varying, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  _ref = require('./list'), List = _ref.List, DerivedList = _ref.DerivedList;

  Varying = require('../core/varying').Varying;

  util = require('../util/util');

  MappedList = (function(_super) {
    __extends(MappedList, _super);

    function MappedList(parent, mapper, options) {
      var elem, _i, _len, _ref1,
        _this = this;

      this.parent = parent;
      this.mapper = mapper;
      this.options = options != null ? options : {};
      MappedList.__super__.constructor.call(this);
      this._mappers = new List();
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

    MappedList.prototype._add = function(elem, idx) {
      var mapped, wrapped,
        _this = this;

      wrapped = Varying.ly(elem);
      mapped = wrapped.map(this.mapper);
      mapped.destroyWith(wrapped);
      this._mappers.add(mapped, idx);
      mapped.on('changed', function(newValue) {
        return _this._put(newValue, _this._mappers.list.indexOf(mapped));
      });
      return MappedList.__super__._add.call(this, mapped.value, idx);
    };

    MappedList.prototype._removeAt = function(idx) {
      var _ref1;

      if ((_ref1 = this._mappers.removeAt(idx)) != null) {
        _ref1.destroy();
      }
      return MappedList.__super__._removeAt.call(this, idx);
    };

    return MappedList;

  })(DerivedList);

  util.extend(module.exports, {
    MappedList: MappedList
  });

}).call(this);
