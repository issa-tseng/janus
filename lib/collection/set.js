(function() {
  var List, Set, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  List = require('./list').List;

  util = require('../util/util');

  Set = (function(_super) {
    __extends(Set, _super);

    function Set() {
      _ref = Set.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Set.prototype.has = function(elem) {
      return this.list.indexOf(elem) >= 0;
    };

    Set.prototype.add = function(elems) {
      var elem, _i, _len, _results,
        _this = this;

      if (!util.isArray(elems)) {
        elems = [elems];
      }
      _results = [];
      for (_i = 0, _len = elems.length; _i < _len; _i++) {
        elem = elems[_i];
        if (this.has(elem)) {
          continue;
        }
        this.list.push(elem);
        this.emit('added', elem);
        if (typeof elem.emit === "function") {
          elem.emit('addedTo', this);
        }
        if (elem instanceof Base) {
          _results.push(this.listenTo(elem, 'destroying', function() {
            return _this.remove(elem);
          }));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    return Set;

  })(List);

  util.extend(module.exports, {
    Set: Set
  });

}).call(this);
