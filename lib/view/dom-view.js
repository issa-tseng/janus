(function() {
  var DomView, List, View, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  View = require('./view').View;

  List = require('../collection/list').List;

  DomView = (function(_super) {
    __extends(DomView, _super);

    DomView.prototype.templateClass = null;

    function DomView(subject, options) {
      var _this = this;

      this.subject = subject;
      this.options = options != null ? options : {};
      DomView.__super__.constructor.call(this, this.subject, this.options);
      this.on('appended', function() {
        var subview, _i, _len, _ref;

        if (_this.artifact().closest('body').length > 0) {
          _this.emit('appendedToDocument');
          if (_this._subviews != null) {
            _ref = _this._subviews.list;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              subview = _ref[_i];
              subview.emit('appended');
            }
          }
        }
        return null;
      });
      this.destroyWith(this.subject);
    }

    DomView.prototype.markup = function() {
      var node;

      return ((function() {
        var _i, _len, _ref, _results;

        _ref = this.artifact().get();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
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
        dom: dom
      });
      this._setTemplaterData(false);
      return null;
    };

    DomView.prototype._setTemplaterData = function(shouldRender) {
      return this._templater.data(this.subject, this._auxData(), shouldRender);
    };

    DomView.prototype._auxData = function() {
      var _ref;

      return (_ref = this.options.aux) != null ? _ref : {};
    };

    DomView.prototype._app = function() {
      var _ref,
        _this = this;

      return (_ref = this._app$) != null ? _ref : this._app$ = (function() {
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

    DomView.prototype.wireEvents = function() {
      var dom, view, _i, _len, _ref;

      if (this._wired === true) {
        return;
      }
      this._wired = true;
      dom = this.artifact();
      dom.data('view', this);
      this._wireEvents();
      if (this._subviews != null) {
        _ref = this._subviews.list;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          view = _ref[_i];
          if (view != null) {
            view.wireEvents();
          }
        }
      }
      return null;
    };

    DomView.prototype.destroy = function() {
      var _base;

      if (this._artifact != null) {
        if (typeof (_base = this.artifact()).trigger === "function") {
          _base.trigger('destroying');
        }
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
