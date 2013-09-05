(function() {
  var VaryingView, ViewContainer, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../../util/util');

  ViewContainer = require('./view-container').ViewContainer;

  VaryingView = (function(_super) {
    __extends(VaryingView, _super);

    function VaryingView() {
      _ref = VaryingView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    VaryingView.prototype._render = function() {
      var dom, handleValue, replaceWith,
        _this = this;
      dom = VaryingView.__super__._render.call(this);
      replaceWith = function(newDom) {
        dom.replaceWith(newDom);
        return dom = newDom;
      };
      handleValue = function(newValue) {
        var newView;
        if (_this._value != null) {
          replaceWith(_this._templater.dom());
          _this._removeView(_this._value);
        }
        if (newValue != null) {
          newView = _this._getView(newValue);
          if (newView != null) {
            replaceWith(newView.artifact());
            newView.emit('appended');
          }
        }
        return _this._value = newValue;
      };
      this.subject.on('changed', handleValue);
      handleValue(this.subject.value);
      return dom;
    };

    VaryingView.prototype._childContext = function() {
      var _ref1;
      return (_ref1 = this.options.itemContext) != null ? _ref1 : this.options.libraryContext;
    };

    return VaryingView;

  })(ViewContainer);

  util.extend(module.exports, {
    VaryingView: VaryingView
  });

}).call(this);
