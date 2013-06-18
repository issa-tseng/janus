(function() {
  var Model, ViewModel, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Model = require('./model').Model;

  ViewModel = (function(_super) {
    __extends(ViewModel, _super);

    function ViewModel() {
      _ref = ViewModel.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    return ViewModel;

  })(Model);

}).call(this);
