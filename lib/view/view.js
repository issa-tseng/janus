(function() {
  var Base, View, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Base = require('../core/base').Base;

  util = require('../util/util');

  View = (function(_super) {
    __extends(View, _super);

    function View(subject, options) {
      var attrs;

      this.options = options != null ? options : {};
      View.__super__.constructor.call(this);
      this.subject = this.constructor.viewModelClass != null ? (attrs = this.options.settings != null ? {
        settings: this.options.settings,
        subject: subject
      } : {
        subject: subject
      }, new this.constructor.viewModelClass(attrs)) : subject;
      if (typeof this._initialize === "function") {
        this._initialize();
      }
    }

    View.prototype.artifact = function() {
      var _ref;

      return (_ref = this._artifact) != null ? _ref : this._artifact = this._render();
    };

    View.prototype._render = function() {};

    View.prototype.wireEvents = function() {
      if (!this._wired) {
        this._wireEvents();
      }
      this._wired = true;
      return null;
    };

    View.prototype._wireEvents = function() {};

    View.prototype.bind = function(artifact) {
      this._artifact = artifact;
      this._bind(artifact);
      return null;
    };

    View.prototype._bind = function() {};

    return View;

  })(Base);

  util.extend(module.exports, {
    View: View
  });

}).call(this);
