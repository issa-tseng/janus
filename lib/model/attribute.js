(function() {
  var Attribute, CollectionAttribute, DateAttribute, EnumAttribute, List, Model, ModelAttribute, NumberAttribute, ObjectAttribute, TextAttribute, util, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  Model = require('./model').Model;

  List = require('../collection/list').List;

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

    Attribute.prototype.writeDefault = false;

    Attribute.deserialize = function(data) {
      return data;
    };

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
      return new List([]);
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

    DateAttribute.deserialize = function(data) {
      return new Date(data);
    };

    return DateAttribute;

  })(Attribute);

  ModelAttribute = (function(_super) {
    __extends(ModelAttribute, _super);

    function ModelAttribute() {
      _ref4 = ModelAttribute.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    ModelAttribute.modelClass = Model;

    ModelAttribute.deserialize = function(data) {
      return this.modelClass.deserialize(data);
    };

    ModelAttribute.prototype.serialize = function() {
      return this.constructor.modelClass.serialize(this.getValue());
    };

    return ModelAttribute;

  })(Attribute);

  CollectionAttribute = (function(_super) {
    __extends(CollectionAttribute, _super);

    function CollectionAttribute() {
      _ref5 = CollectionAttribute.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    CollectionAttribute.collectionClass = Array;

    CollectionAttribute.deserialize = function(data) {
      return this.collectionClass.deserialize(data);
    };

    return CollectionAttribute;

  })(Attribute);

  util.extend(module.exports, {
    Attribute: Attribute,
    TextAttribute: TextAttribute,
    EnumAttribute: EnumAttribute,
    NumberAttribute: NumberAttribute,
    DateAttribute: DateAttribute,
    ModelAttribute: ModelAttribute,
    CollectionAttribute: CollectionAttribute
  });

}).call(this);
