(function() {
  var Base, DerivedList, List, Model, OrderedCollection, Reference, Varying, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  Base = require('../core/base').Base;

  Varying = require('../core/varying').Varying;

  OrderedCollection = require('./types').OrderedCollection;

  Model = require('../model/model').Model;

  Reference = require('../model/reference').Reference;

  util = require('../util/util');

  List = (function(_super) {
    __extends(List, _super);

    function List(list, options) {
      if (list == null) {
        list = [];
      }
      this.options = options != null ? options : {};
      List.__super__.constructor.call(this, {}, this.options);
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
        if (elem != null) {
          if (typeof elem.emit === "function") {
            elem.emit('addedTo', this, idx + subidx);
          }
        }
        if (elem instanceof Base) {
          (function(elem) {
            return _this.listenTo(elem, 'destroying', function() {
              return _this.remove(elem);
            });
          })(elem);
        }
      }
      return elems;
    };

    List.prototype.remove = function(which) {
      var idx;
      idx = this.list.indexOf(which);
      if (!(util.isNumber(idx) && idx >= 0)) {
        return false;
      }
      return this.removeAt(idx);
    };

    List.prototype.removeAt = function(idx) {
      var removed;
      removed = this.list.splice(idx, 1)[0];
      this.emit('removed', removed, idx);
      if (removed != null) {
        if (typeof removed.emit === "function") {
          removed.emit('removedFrom', this, idx);
        }
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
      if (elem != null) {
        if (typeof elem.emit === "function") {
          elem.emit('movedIn', this.list, idx, oldIdx);
        }
      }
      return elem;
    };

    List.prototype.removeAll = function() {
      var elem, idx, oldList, _i, _len, _ref;
      _ref = this.list;
      for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
        elem = _ref[idx];
        this.emit('removed', elem, idx);
        if (elem != null) {
          if (typeof elem.emit === "function") {
            elem.emit('removedFrom', this, idx);
          }
        }
      }
      oldList = this.list;
      this.list = [];
      return oldList;
    };

    List.prototype.at = function(idx) {
      if (idx >= 0) {
        return this.list[idx];
      } else {
        return this.list[this.list.length + idx];
      }
    };

    List.prototype.watchAt = function(idx) {
      var result;
      result = new Varying(this.at(idx));
      this.on('added', function() {
        return result.setValue(this.at(idx));
      });
      this.on('removed', function() {
        return result.setValue(this.at(idx));
      });
      return result;
    };

    List.prototype.watchLength = function() {
      var result;
      result = new Varying(this.list.length);
      this.on('added', function() {
        return result.setValue(this.list.length);
      });
      this.on('removed', function() {
        return result.setValue(this.list.length);
      });
      return result;
    };

    List.prototype.put = function() {
      var elem, elems, idx, removed, subidx, _i, _j, _len, _len1, _ref;
      idx = arguments[0], elems = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (this.list[idx] == null) {
        this.list[idx] = null;
        delete this.list[idx];
      }
      removed = (_ref = this.list).splice.apply(_ref, [idx, elems.length].concat(__slice.call(elems)));
      for (subidx = _i = 0, _len = removed.length; _i < _len; subidx = ++_i) {
        elem = removed[subidx];
        if (!(elem != null)) {
          continue;
        }
        this.emit('removed', elem, idx + subidx);
        if (elem != null) {
          if (typeof elem.emit === "function") {
            elem.emit('removedFrom', this, idx + subidx);
          }
        }
      }
      for (subidx = _j = 0, _len1 = elems.length; _j < _len1; subidx = ++_j) {
        elem = elems[subidx];
        this.emit('added', elem, idx + subidx);
        if (elem != null) {
          if (typeof elem.emit === "function") {
            elem.emit('addedTo', this, idx + subidx);
          }
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

    List.prototype.shadow = function() {
      var item, newArray;
      newArray = (function() {
        var _i, _len, _ref, _results;
        _ref = this.list;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          if (item instanceof Model) {
            _results.push(item.shadow());
          } else {
            _results.push(item);
          }
        }
        return _results;
      }).call(this);
      return new this.constructor(newArray, util.extendNew(this.options, {
        parent: this
      }));
    };

    List.prototype.modified = function(deep) {
      var i, parentValue, value, _i, _len, _ref;
      if (deep == null) {
        deep = true;
      }
      if (this._parent == null) {
        return false;
      }
      if (this._parent.list.length !== this.list.length) {
        return true;
      }
      _ref = this.list;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        value = _ref[i];
        parentValue = this._parent.list[i];
        if (value instanceof Model) {
          if (deep === true) {
            if (value.modified()) {
              return true;
            }
          } else {
            if (parentValue !== value._parent) {
              return true;
            }
          }
        } else {
          if (parentValue !== value) {
            return true;
          }
        }
      }
      return false;
    };

    List.deserialize = function(data) {
      var datum, items;
      items = (function() {
        var _i, _len, _results;
        if ((this.modelClass != null) && (this.modelClass.prototype instanceof Model || this.modelClass.prototype instanceof OrderedCollection)) {
          _results = [];
          for (_i = 0, _len = data.length; _i < _len; _i++) {
            datum = data[_i];
            _results.push(this.modelClass.deserialize(datum));
          }
          return _results;
        } else {
          return data.slice();
        }
      }).call(this);
      return new this(items);
    };

    List._plainObject = function(method, list) {
      var child, _i, _len, _ref, _results;
      _ref = list.list;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        if (child instanceof Reference) {
          child = child.value instanceof Model ? child.value : child.flatValue;
        }
        if (child[method] != null) {
          _results.push(child[method]());
        } else {
          _results.push(child);
        }
      }
      return _results;
    };

    return List;

  })(OrderedCollection);

  DerivedList = (function(_super) {
    var method, _i, _len, _ref1;

    __extends(DerivedList, _super);

    function DerivedList() {
      _ref = DerivedList.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    _ref1 = ['add', 'remove', 'removeAt', 'removeAll', 'put', 'putAll', 'move'];
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      method = _ref1[_i];
      DerivedList.prototype["_" + method] = DerivedList.__super__[method];
      DerivedList.prototype[method] = (function() {});
    }

    DerivedList.prototype.shadow = function() {
      return this;
    };

    return DerivedList;

  })(List);

  util.extend(module.exports, {
    List: List,
    DerivedList: DerivedList
  });

}).call(this);
