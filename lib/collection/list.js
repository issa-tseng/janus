(function() {
  var Base, DerivedList, List, Model, OrderedCollection, Reference, Varying, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

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
      elems = this._processElements(elems);
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
      var elem, _results;

      _results = [];
      while (this.list.length > 0) {
        elem = this.list.pop();
        this.emit('removed', elem, this.list.length);
        if (elem != null) {
          if (typeof elem.emit === "function") {
            elem.emit('removedFrom', this, this.list.length);
          }
        }
        _results.push(elem);
      }
      return _results;
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
      elems = this._processElements(elems);
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
          this.add(this._processElements([elem])[0], i);
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
      var i, isDeep, parentValue, value, _i, _len, _ref, _ref1, _ref2;

      if (this._parent == null) {
        return false;
      }
      if (this._parent.list.length !== this.list.length) {
        return true;
      }
      isDeep = deep == null ? true : util.isFunction(deep) ? deep(this) : deep === true;
      _ref = this.list;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        value = _ref[i];
        parentValue = this._parent.list[i];
        if (value instanceof Reference) {
          value = (_ref1 = value.value) != null ? _ref1 : value.flatValue;
        }
        if (parentValue instanceof Reference) {
          parentValue = (_ref2 = parentValue.value) != null ? _ref2 : parentValue.flatValue;
        }
        if (value instanceof Model) {
          if (__indexOf.call(value.originals(), parentValue) < 0) {
            return true;
          }
          if (isDeep === true && value.modified(deep)) {
            return true;
          }
        } else {
          if (parentValue !== value && !((parentValue == null) && (value == null))) {
            return true;
          }
        }
      }
      return false;
    };

    List.prototype.watchModified = function(deep) {
      var isDeep, _ref, _ref1,
        _this = this;

      if (this._parent == null) {
        return new Varying(false);
      }
      isDeep = deep == null ? true : util.isFunction(deep) ? deep(this) : deep === true;
      if (isDeep === true) {
        return (_ref = this._watchModifiedDeep$) != null ? _ref : this._watchModifiedDeep$ = (function() {
          var model, react, result, uniqSubmodels, watchModel, _i, _len, _ref1;

          result = new Varying(_this.modified(deep));
          react = function() {
            return result.setValue(_this.modified(deep));
          };
          _this.on('added', react);
          _this.on('removed', react);
          _this.on('moved', react);
          watchModel = function(model) {
            return result.listenTo(model.watchModified(deep), 'changed', function(isChanged) {
              if (isChanged === true) {
                return result.setValue(true);
              } else {
                return react();
              }
            });
          };
          uniqSubmodels = _this.map(function(elem) {
            return elem;
          }).filter(function(elem) {
            return elem instanceof Model;
          }).uniq();
          _ref1 = uniqSubmodels.list;
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            model = _ref1[_i];
            watchModel(model);
          }
          uniqSubmodels.on('added', function(newModel) {
            return watchModel(newModel);
          });
          uniqSubmodels.on('removed', function(oldModel) {
            return result.unlistenTo(oldModel.watchModified(deep));
          });
          return result;
        })();
      } else {
        return (_ref1 = this._watchModified$) != null ? _ref1 : this._watchModified$ = (function() {
          var react, result;

          result = new Varying(_this.modified(deep));
          react = function() {
            if (_this.list.length !== _this._parent.list.length) {
              return result.setValue(true);
            } else {
              return result.setValue(_this.modified(deep));
            }
          };
          _this.on('added', react);
          _this.on('removed', react);
          return result;
        })();
      }
    };

    List.prototype._processElements = function(elems) {
      var elem, _i, _len, _results;

      _results = [];
      for (_i = 0, _len = elems.length; _i < _len; _i++) {
        elem = elems[_i];
        if (this._parent != null) {
          if (elem instanceof Model) {
            _results.push(elem.shadow());
          } else if (elem instanceof Reference) {
            _results.push(elem.map(function(value) {
              if (value instanceof Model) {
                return value.shadow();
              } else {
                return value;
              }
            }));
          } else {
            _results.push(elem);
          }
        } else {
          _results.push(elem);
        }
      }
      return _results;
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

    List.serialize = function(list) {
      var child, _i, _len, _ref, _results;

      _ref = list.list;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        if (child instanceof Reference) {
          child = child.value instanceof Model ? child.value : child.flatValue;
        }
        if (child.serialize != null) {
          _results.push(child.serialize());
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
