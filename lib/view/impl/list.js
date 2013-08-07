(function() {
  var ListView, Varying, ViewContainer, reference, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../../util/util');

  ViewContainer = require('./view-container').ViewContainer;

  reference = require('../../model/reference');

  Varying = require('../../core/varying').Varying;

  ListView = (function(_super) {
    __extends(ListView, _super);

    function ListView() {
      _ref = ListView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    ListView.prototype._render = function() {
      var dom,
        _this = this;

      dom = this._dom = ListView.__super__._render.call(this);
      this._add(this.subject.list);
      this.listenTo(this.subject, 'added', function(item, idx) {
        return _this._add(item, idx);
      });
      this.listenTo(this.subject, 'removed', function(item) {
        return _this._remove(item);
      });
      return dom;
    };

    ListView.prototype._add = function(items, idx) {
      var afterDom, insert, item, _fn, _i, _len,
        _this = this;

      if (!util.isArray(items)) {
        items = [items];
      }
      afterDom = null;
      insert = function(elem) {
        if (_this._dom.children().length === 0) {
          _this._dom.append(elem);
        } else if (afterDom != null) {
          afterDom.after(elem);
        } else if (util.isNumber(idx)) {
          if (idx === 0) {
            _this._dom.prepend(elem);
          } else {
            afterDom = _this._dom.children(":nth-child(" + idx + ")");
            afterDom.after(elem);
          }
        } else {
          afterDom = _this._dom.children(':last-child');
          afterDom.after(elem);
        }
        return afterDom = elem;
      };
      _fn = function(item) {
        var view, viewDom, _ref1;

        view = viewDom = null;
        if (item instanceof reference.RequestReference && item.value instanceof reference.RequestResolver) {
          item.value.resolve(_this.options.app);
        }
        view = _this._getView(item);
        viewDom = (_ref1 = view != null ? view.artifact() : void 0) != null ? _ref1 : _this._emptyDom();
        insert(viewDom);
        if (view != null) {
          view.emit('appended');
          if (_this._wired === true) {
            return view.wireEvents();
          }
        }
      };
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        _fn(item);
      }
      return null;
    };

    ListView.prototype._remove = function(items) {
      var item, _i, _len;

      if (!util.isArray(items)) {
        items = [items];
      }
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        this._removeView(item);
      }
      return null;
    };

    return ListView;

  })(ViewContainer);

  util.extend(module.exports, {
    ListView: ListView
  });

}).call(this);
