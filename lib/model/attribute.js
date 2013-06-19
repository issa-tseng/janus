(function() {
  var Attribute, DateAttribute, EnumAttribute, Model, ModelAttribute, NumberAttribute, TextAttribute, util, _ref, _ref1, _ref2, _ref3, _ref4,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  Model = require('./model').Model;

  Attribute = (function(_super) {
    __extends(Attribute, _super);

    function Attribute(model, key) {
      this.model = model;
      this.key = key;
      Attribute.__super__.constructor.call(this);
      if (typeof this._initialize === "function") {
        this._initialize();
      }
    }

    Attribute.prototype.setValue = function(value) {
      return this.model.set(this.key, value);
    };

    Attribute.prototype.getValue = function() {
      return this.model.get(this.key);
    };

    Attribute.prototype.watchValue = function() {
      return this.model.watch(this.key);
    };

    Attribute.prototype["default"] = function() {};

    return Attribute;

  })(Model);

  TextAttribute = (function(_super) {
    __extends(TextAttribute, _super);

    function TextAttribute() {
      _ref = TextAttribute.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    return TextAttribute;

  })(Attribute);

  EnumAttribute = (function(_super) {
    __extends(EnumAttribute, _super);

    function EnumAttribute() {
      _ref1 = EnumAttribute.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    EnumAttribute.prototype.values = function() {
      return [];
    };

    return EnumAttribute;

  })(Attribute);

  NumberAttribute = (function(_super) {
    __extends(NumberAttribute, _super);

    function NumberAttribute() {
      _ref2 = NumberAttribute.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    return NumberAttribute;

  })(Attribute);

  DateAttribute = (function(_super) {
    __extends(DateAttribute, _super);

    function DateAttribute() {
      _ref3 = DateAttribute.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    return DateAttribute;

  })(Attribute);

  ModelAttribute = (function(_super) {
    __extends(ModelAttribute, _super);

    function ModelAttribute() {
      _ref4 = ModelAttribute.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    return ModelAttribute;

  })(Attribute);

  util.extend(module.exports, {
    Attribute: Attribute,
    TextAttribute: TextAttribute,
    EnumAttribute: EnumAttribute,
    NumberAttribute: NumberAttribute,
    DateAttribute: DateAttribute,
    ModelAttribute: ModelAttribute
  });

}).call(this);
