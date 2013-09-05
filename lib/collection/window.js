(function() {
  var List, Model, Varying, Window, attribute, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  Model = require('../model/model').Model;

  attribute = require('../model/attribute');

  List = require('./list').List;

  Varying = require('../core/varying').Varying;

  Window = (function(_super) {
    var _ref1;

    __extends(Window, _super);

    function Window() {
      _ref = Window.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Window.attribute('page', (function(_super1) {
      __extends(_Class, _super1);

      function _Class() {
        _ref1 = _Class.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      _Class.prototype.values = function() {
        return this.model.watch('pageCount').map(function(count) {
          var _i, _results;
          return new List((function() {
            _results = [];
            for (var _i = 1; 1 <= count ? _i <= count : _i >= count; 1 <= count ? _i++ : _i--){ _results.push(_i); }
            return _results;
          }).apply(this));
        });
      };

      _Class.prototype["default"] = function() {
        return 1;
      };

      return _Class;

    })(attribute.EnumAttribute));

    Window.bind('pageCount').fromVarying(function() {
      return this.watch('parent').map(function(lazyList) {
        return lazyList.length();
      });
    }).and('pageSize').flatMap(function(total, pageSize) {
      return Math.ceil(total / pageSize);
    });

    Window.bind('list').fromVarying(function() {
      var range,
        _this = this;
      range = null;
      return Varying.combine([this.watch('parent'), this.watch('page'), this.watch('pageSize')], function(parent, page, pageSize) {
        if (range != null) {
          range.destroy();
        }
        return range = (parent != null) && (page != null) && (pageSize != null) ? parent.range(page * pageSize, page * pageSize + pageSize) : null;
      });
    });

    return Window;

  })(Model);

  util.extend(module.exports, {
    Window: Window
  });

}).call(this);
