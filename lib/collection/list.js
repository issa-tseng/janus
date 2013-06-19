(function() {
  var Base, List, OrderedIncrementalList, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  Base = require('../core/base').Base;

  OrderedIncrementalList = require('./types').OrderedIncrementalList;

  util = require('../util/util');

  List = (function(_super) {
    __extends(List, _super);

    function List(list, options) {
      if (list == null) {
        list = [];
      }
      this.options = options != null ? options : {};
      List.__super__.constructor.call(this);
      this.list = [];
      this.add(list);
      if (typeof this._initialize === "function") {
        this._initialize();
      }
    }

    List.prototype.add = function(elems, idx) {
      var elem, subidx, _i, _len,
        _this = this;

      if (idx == null) {
        idx = this.list.length;
      }
      if (!util.isArray(elems)) {
        elems = [elems];
      }
      Array.prototype.splice.apply(this.list, [idx, 0].concat(elems));
      for (subidx = _i = 0, _len = elems.length; _i < _len; subidx = ++_i) {
        elem = elems[subidx];
        this.emit('added', elem, idx + subidx);
        if (typeof elem.emit === "function") {
          elem.emit('addedTo', this, idx + subidx);
        }
        if (elem instanceof Base) {
          this.listenTo(elem, 'destroying', function() {
            return _this.remove(elem);
          });
        }
      }
      return elems;
    };

    List.prototype.remove = function(which) {
      var idx, removed;

      idx = this.list.indexOf(which);
      if (!(util.isNumber(idx) && idx >= 0)) {
        return false;
      }
      removed = this.list.splice(idx, 1)[0];
      this.emit('removed', removed, idx);
      if (typeof removed.emit === "function") {
        removed.emit('removedFrom', this, idx);
      }
      return removed;
    };

    List.prototype.move = function(elem, idx) {
      var oldIdx;

      oldIdx = this.list.indexOf(elem);
      if (!(oldIdx >= 0)) {
        return;
      }
      this.list.splice(oldIdx, 1);
      this.list.splice(idx, 0, elem);
      this.emit('moved', elem, idx, oldIdx);
      elem.emit('movedIn', this.list, idx, oldIdx);
      return elem;
    };

    List.prototype.removeAll = function() {
      var elem, idx, oldList, _i, _len, _ref;

      _ref = this.list;
      for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
        elem = _ref[idx];
        this.emit('removed', elem, idx);
        if (typeof elem.emit === "function") {
          elem.emit('removedFrom', this, idx);
        }
      }
      oldList = this.list;
      this.list = [];
      return oldList;
    };

    List.prototype.at = function(idx) {
      return this.list[idx];
    };

    List.prototype.put = function() {
      var elem, elems, idx, removed, subidx, _i, _j, _len, _len1;

      idx = arguments[0], elems = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (this.list[idx] == null) {
        this.list[idx] = null;
        delete this.list[idx];
      }
      removed = this.list.splice(idx, elems.length, elems);
      for (subidx = _i = 0, _len = removed.length; _i < _len; subidx = ++_i) {
        elem = removed[subidx];
        this.emit('removed', elem, idx + subidx);
        if (typeof elem.emit === "function") {
          elem.emit('removedFrom', this, idx + subidx);
        }
      }
      for (subidx = _j = 0, _len1 = elems.length; _j < _len1; subidx = ++_j) {
        elem = elems[subidx];
        this.emit('added', elem, idx + subidx);
        if (typeof elem.emit === "function") {
          elem.emit('addedTo', this, idx + subidx);
        }
      }
      return removed;
    };

    List.prototype.putAll = function(list) {
      var elem, i, oldIdx, oldList, _i, _j, _len, _len1;

      oldList = this.list.slice();
      for (_i = 0, _len = oldList.length; _i < _len; _i++) {
        elem = oldList[_i];
        if (!(list.indexOf(elem) >= 0)) {
          this.remove(elem);
        }
      }
      for (i = _j = 0, _len1 = list.length; _j < _len1; i = ++_j) {
        elem = list[i];
        if (this.list[i] === elem) {
          continue;
        }
        oldIdx = this.list.indexOf(elem);
        if (oldIdx >= 0) {
          this.move(elem, i);
        } else {
          this.add(elem, i);
        }
      }
      return list;
    };

    return List;

  })(OrderedIncrementalList);

  util.extend(module.exports, {
    List: List
  });

}).call(this);
