(function() {
  var DomView, List, View, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  View = require('./view').View;

  List = require('../collection/list').List;

  DomView = (function(_super) {
    __extends(DomView, _super);

    function DomView() {
      _ref = DomView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    DomView.prototype.templateClass = null;

    DomView.prototype.markup = function() {
      var node;

      return ((function() {
        var _i, _len, _ref1, _results;

        _ref1 = this.artifact().get();
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          node = _ref1[_i];
          _results.push(node.outerHTML);
        }
        return _results;
      }).call(this)).join('');
    };

    DomView.prototype._render = function() {
      var dom;

      this._templater = new this.templateClass(util.extendNew({
        app: this._app()
      }, this._templaterOptions()));
      dom = this._templater.dom();
      this._setTemplaterData();
      return dom;
    };

    DomView.prototype._templaterOptions = function() {
      return {};
    };

    DomView.prototype._bind = function(dom) {
      this._templater = new this.templateClass({
        app: this._app(),
        dom: dom,
        bindOnly: true
      });
      this._setTemplaterData();
      return null;
    };

    DomView.prototype._setTemplaterData = function() {
      return this._templater.data(this.subject, this._auxData());
    };

    DomView.prototype._auxData = function() {
      return {};
    };

    DomView.prototype._app = function() {
      var _ref1,
        _this = this;

      return (_ref1 = this._app$) != null ? _ref1 : this._app$ = (function() {
        var library;

        library = _this.options.app.libraries.views.newEventBindings();
        library.destroyWith(_this);
        _this._subviews = new List();
        _this.listenTo(library, 'got', function(view) {
          if (_this._wired === true) {
            view.wireEvents();
          }
          return _this._subviews.add(view);
        });
        return _this.options.app.withViewLibrary(library);
      })();
    };

    DomView.prototype._wireEvents = function() {
      var view, _i, _len, _ref1;

      if (this._subviews != null) {
        _ref1 = this._subviews.list;
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          view = _ref1[_i];
          if (view != null) {
            view.wireEvents();
          }
        }
      }
      return null;
    };

    DomView.prototype.destroy = function() {
      if (this._artifact != null) {
        this.artifact().remove();
      }
      return DomView.__super__.destroy.call(this);
    };

    return DomView;

  })(View);

  util.extend(module.exports, {
    DomView: DomView
  });

}).call(this);
