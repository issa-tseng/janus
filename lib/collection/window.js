(function() {
  var Model, Varying, Window, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  Model = require('../model/model');

  Varying = require('../core/varying').Varying;

  Window = (function(_super) {
    __extends(Window, _super);

    function Window() {
      _ref = Window.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Window.prototype._initialize = function() {
      var range,
        _this = this;

      range = null;
      return Varying.combine([this.watch('parent'), this.watch('page'), this.watch('pageSize')], function(parent, idx, length) {
        if (range != null) {
          range.destroy();
        }
        range = parent.range(page * pageSize, page * pageSize + pageSize);
        return _this.set('list', range.value);
      });
    };

    return Window;

  })(Model);

  util.extend(module.exports, {
    Window: Window
  });

}).call(this);
