(function() {
  var Model, PageModel, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  Model = require('./model').Model;

  PageModel = (function(_super) {
    __extends(PageModel, _super);

    function PageModel() {
      _ref = PageModel.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    PageModel.prototype.resolve = function() {
      return this._render();
    };

    PageModel.prototype._render = function() {};

    return PageModel;

  })(Model);

  util.extend(module.exports, {
    PageModel: PageModel
  });

}).call(this);
