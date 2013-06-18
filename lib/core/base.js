(function() {
  var Base, EventEmitter, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('eventemitter2').EventEmitter2;

  util = require('../util/util');

  Base = (function(_super) {
    __extends(Base, _super);

    function Base() {
      Base.__super__.constructor.call(this, {
        delimiter: ':',
        maxListeners: 0
      });
      this.setMaxListeners(0);
      this._outwardListeners = [];
      this._id = util.uniqueId();
      null;
    }

    Base.prototype.listenTo = function(target, event, handler) {
      this._outwardListeners.push(arguments);
      target.on(event, handler);
      return this;
    };

    Base.prototype.destroy = function() {
      var event, handler, target, _i, _len, _ref, _ref1;

      this.emit('destroying');
      _ref = this._outwardListeners;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _ref1 = _ref[_i], target = _ref1[0], event = _ref1[1], handler = _ref1[2];
        if (target != null) {
          target.off(event, handler);
        }
      }
      return this.removeAllListeners();
    };

    Base.prototype.destroyWith = function(other) {
      var _this = this;

      return this.listenTo(other, 'destroying', function() {
        return _this.destroy();
      });
    };

    return Base;

  })(EventEmitter);

  util.extend(module.exports, {
    Base: Base
  });

}).call(this);
