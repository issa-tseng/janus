(function() {
  var DomView, ListView, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../../util/util');

  DomView = require('../dom-view').DomView;

  ListView = (function(_super) {
    __extends(ListView, _super);

    function ListView() {
      _ref = ListView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    ListView.prototype._initialize = function() {
      var _base, _ref1;

      return (_ref1 = (_base = this.options).childOpts) != null ? _ref1 : _base.childOpts = {};
    };

    ListView.prototype._render = function() {
      var dom,
        _this = this;

      dom = this._dom = ListView.__super__._render.call(this);
      this._views = {};
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
      var afterDom, insert, item, view, viewDom, wrappedViewDom, _i, _len,
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
          afterDom = _this._dom.children(":nth-child(" + idx + ")");
          afterDom.after(elem);
        } else {
          afterDom = _this._dom.children(':last-child');
          afterDom.after(elem);
        }
        return afterDom = elem;
      };
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        view = this._getView(item);
        this._views[item._id] = view;
        viewDom = view.artifact();
        wrappedViewDom = this._wrapChild(viewDom);
        insert(viewDom);
        view.emit('appended');
        if (this._wired === true) {
          view.wireEvents();
        }
      }
      return null;
    };

    ListView.prototype._getView = function(item) {
      var view;

      view = item instanceof DomView ? item : this.options.itemView != null ? new this.options.itemView(item, util.extendNew(this.options.childOpts, {
        app: this.options.app
      })) : this._app().getView(item, {
        context: this.options.itemContext,
        constructorOpts: this.options.childOpts
      });
      if (this._wired === true) {
        view.wireEvents();
      }
      return view;
    };

    ListView.prototype._remove = function(items) {
      var item, _i, _len, _ref1;

      if (!util.isArray(items)) {
        items = [items];
      }
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        if ((_ref1 = this._views[item._id]) != null) {
          _ref1.destroy();
        }
        delete this._views[item._id];
      }
      return null;
    };

    ListView.prototype._wrapChild = function(child) {
      return child.wrap('<li/>').parent();
    };

    ListView.prototype._wireEvents = function() {
      var view, _, _ref1, _results;

      _ref1 = this._views;
      _results = [];
      for (_ in _ref1) {
        view = _ref1[_];
        _results.push(view.wireEvents());
      }
      return _results;
    };

    return ListView;

  })(DomView);

  util.extend(module.exports, {
    ListView: ListView
  });

}).call(this);
