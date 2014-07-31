(function() {
  var DomView, Varying, ViewContainer, reference, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../../util/util');

  DomView = require('../dom-view').DomView;

  reference = require('../../model/reference');

  Varying = require('../../core/varying').Varying;

  ViewContainer = (function(_super) {
    __extends(ViewContainer, _super);

    function ViewContainer() {
      _ref = ViewContainer.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    ViewContainer.prototype._initialize = function() {
      var _base, _ref1;

      this._views = {};
      return (_ref1 = (_base = this.options).childOpts) != null ? _ref1 : _base.childOpts = {};
    };

    ViewContainer.prototype._removeView = function(subject) {
      var _ref1, _ref2;

      if (subject == null) {
        return null;
      }
      if ((_ref1 = this._views[(_ref2 = subject._id) != null ? _ref2 : subject]) != null) {
        _ref1.destroy();
      }
      delete this._views[subject._id];
      return null;
    };

    ViewContainer.prototype._getView = function(subject) {
      var result, view, _ref1;

      if (subject == null) {
        return null;
      }
      view = subject instanceof DomView ? (this._subviews.add(subject), subject) : this.options.itemView != null ? (result = new this.options.itemView(subject, util.extendNew(this.options.childOpts, {
        app: this.options.app
      })), this._subviews.add(result), result) : this._app().getView(subject, {
        context: this._childContext(),
        constructorOpts: this.options.childOpts
      });
      this._views[(_ref1 = subject._id) != null ? _ref1 : subject] = view;
      if (this._wired === true) {
        if (view != null) {
          view.wireEvents();
        }
      }
      return view;
    };

    ViewContainer.prototype._childContext = function() {
      return this.options.itemContext;
    };

    return ViewContainer;

  })(DomView);

  util.extend(module.exports, {
    ViewContainer: ViewContainer
  });

}).call(this);
