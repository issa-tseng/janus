(function() {
  var FilteredList, List, OrderedCollection, Varying, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  List = require('./list').List;

  OrderedCollection = require('./types').OrderedCollection;

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
      this.list = [];
      this._initElems(this.parent.list);
      if (typeof this._initialize === "function") {
        this._initialize();
      }
      this.parent.on('added', function(elem) {
        return _this._initElems(elem);
      });
      this.parent.on('removed', function(elem) {
        return _this._remove(elem);
      });
    }

    FilteredList.prototype._initElems = function(elems) {
      var elem, result, _i, _len,
        _this = this;

      if (!util.isArray(elems)) {
        elems = [elems];
      }
      for (_i = 0, _len = elems.length; _i < _len; _i++) {
        elem = elems[_i];
        result = this.isMember(elem);
        if (result instanceof Varying) {
          (function(elem) {
            var handleChange, lastMembership;

            lastMembership = false;
            handleChange = function(newValue) {
              var membership;

              membership = newValue === true;
              if (lastMembership !== membership) {
                if (membership === true) {
                  _this._add(elem);
                } else {
                  _this._remove(elem);
                }
              }
              return lastMembership = membership;
            };
            result.on('changed', handleChange);
            return handleChange(result.value);
          })(elem);
        } else if (result === true) {
          this._add(elem);
        }
      }
      return elems;
    };

    FilteredList.prototype._add = function(elem) {
      var idx;

      idx = this.list.length;
      this.list.push(elem);
      this.emit('added', elem, idx);
      return typeof elem.emit === "function" ? elem.emit('addedTo', this, idx) : void 0;
    };

    FilteredList.prototype._remove = function(elem) {
      var idx, removed;

      idx = this.list.indexOf(elem);
      if (idx >= 0) {
        removed = this.list.splice(idx, 1)[0];
        this.emit('removed', removed, idx);
        if (typeof removed.emit === "function") {
          removed.emit('removedFrom', this, idx);
        }
        return removed;
      }
    };

    return FilteredList;

  })(OrderedCollection);

  util.extend(module.exports, {
    FilteredList: FilteredList
  });

}).call(this);
