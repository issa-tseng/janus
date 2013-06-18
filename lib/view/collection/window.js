(function() {
  var DomView, Window, WindowView, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../../util/util');

  Window = require('../../collection/window').Window;

  DomView = require('../dom-view').DomView;

  WindowView = (function(_super) {
    __extends(WindowView, _super);

    function WindowView() {
      _ref = WindowView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    WindowView.prototype._render = function() {
      var dom;

      dom = this._dom = WindowView.__super__._render.call(this);
      return this.subject.watch('list').on('changed', function(list) {
        return dom.empty().append(this.options.app.getView(list).artifact());
      });
    };

    return WindowView;

  })(DomView);

  util.extend(module.exports, {
    WindowView: WindowView
  });

}).call(this);
