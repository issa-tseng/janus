(function() {
  var Attribute, BooleanAttribute, CollectionAttribute, DateAttribute, EnumAttribute, List, Model, ModelAttribute, NumberAttribute, ObjectAttribute, ShellModel, TextAttribute, Varying, util, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  Model = require('./model').Model;

  Varying = require('../core/varying').Varying;

  List = require('../collection/list').List;

  Attribute = (function(_super) {
    __extends(Attribute, _super);

    function Attribute(model, key) {
      this.model = model;
      this.key = key;
      Attribute.__super__.constructor.call(this);
      if (this.model == null) {
        this.model = new ShellModel(this);
      }
      if (typeof this._initialize === "function") {
        this._initialize();
      }
    }

    Attribute.prototype.setValue = function(value) {
      return this.model.set(this.key, value);
    };

    Attribute.prototype.getValue = function() {
      var value;

      value = this.model.get(this.key, true);
      if ((value == null) && (this["default"] != null)) {
        value = this["default"]();
        if (this.writeDefault === true) {
          this.setValue(value);
        }
      }
      return value;
    };

    Attribute.prototype.watchValue = function() {
      return this.model.watch(this.key);
    };

    Attribute.prototype["default"] = function() {};

    Attribute.prototype.writeDefault = false;

    Attribute.prototype.transient = false;

    Attribute.deserialize = function(data) {
      return data;
    };

    Attribute._plainObject = function(method, model, opts) {
      if (opts == null) {
        opts = {};
      }
      return model.getValue();
    };

    Attribute.prototype.serialize = function() {
      if (this.transient !== true) {
        return this.getValue();
      }
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

  ObjectAttribute = (function(_super) {
    __extends(ObjectAttribute, _super);

    function ObjectAttribute() {
      _ref1 = ObjectAttribute.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    return ObjectAttribute;

  })(Attribute);

  EnumAttribute = (function(_super) {
    __extends(EnumAttribute, _super);

    function EnumAttribute() {
      _ref2 = EnumAttribute.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    EnumAttribute.prototype.values = function() {
      return new List([]);
    };

    EnumAttribute.prototype.nullable = false;

    return EnumAttribute;

  })(Attribute);

  NumberAttribute = (function(_super) {
    __extends(NumberAttribute, _super);

    function NumberAttribute() {
      _ref3 = NumberAttribute.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    return NumberAttribute;

  })(Attribute);

  BooleanAttribute = (function(_super) {
    __extends(BooleanAttribute, _super);

    function BooleanAttribute() {
      _ref4 = BooleanAttribute.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    return BooleanAttribute;

  })(Attribute);

  DateAttribute = (function(_super) {
    __extends(DateAttribute, _super);

    function DateAttribute() {
      _ref5 = DateAttribute.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    DateAttribute.deserialize = function(data) {
      return new Date(data);
    };

    return DateAttribute;

  })(Attribute);

  ModelAttribute = (function(_super) {
    __extends(ModelAttribute, _super);

    function ModelAttribute() {
      _ref6 = ModelAttribute.__super__.constructor.apply(this, arguments);
      return _ref6;
    }

    ModelAttribute.modelClass = Model;

    ModelAttribute.deserialize = function(data) {
      return this.modelClass.deserialize(data);
    };

    ModelAttribute._plainObject = function(method, model, opts) {
      if (opts == null) {
        opts = {};
      }
      return model.constructor.modelClass[method](model.getValue(), opts);
    };

    ModelAttribute.prototype.serialize = function() {
      if (this.transient !== true) {
        return this.constructor.modelClass.serialize(this.getValue());
      }
    };

    return ModelAttribute;

  })(Attribute);

  CollectionAttribute = (function(_super) {
    __extends(CollectionAttribute, _super);

    function CollectionAttribute() {
      _ref7 = CollectionAttribute.__super__.constructor.apply(this, arguments);
      return _ref7;
    }

    CollectionAttribute.collectionClass = Array;

    CollectionAttribute.deserialize = function(data) {
      return this.collectionClass.deserialize(data);
    };

    CollectionAttribute.prototype.serialize = function() {
      if (this.transient !== true) {
        return this.constructor.collectionClass.serialize(this.getValue());
      }
    };

    return CollectionAttribute;

  })(Attribute);

  ShellModel = (function() {
    function ShellModel(attribute) {
      this.attribute = attribute;
    }

    ShellModel.prototype.get = function() {
      if (this._value != null) {
        return this._value;
      } else if (this.attribute["default"] != null) {
        return this.attribute["default"]();
      } else {
        return null;
      }
    };

    ShellModel.prototype.set = function(_, value) {
      var _ref8;

      this._value = value;
      return (_ref8 = this._watcher) != null ? _ref8.setValue(value) : void 0;
    };

    ShellModel.prototype.watch = function() {
      var _ref8;

      return (_ref8 = this._watcher) != null ? _ref8 : this._watcher = new Varying(this._value);
    };

    return ShellModel;

  })();

  util.extend(module.exports, {
    Attribute: Attribute,
    TextAttribute: TextAttribute,
    ObjectAttribute: ObjectAttribute,
    EnumAttribute: EnumAttribute,
    NumberAttribute: NumberAttribute,
    BooleanAttribute: BooleanAttribute,
    DateAttribute: DateAttribute,
    ModelAttribute: ModelAttribute,
    CollectionAttribute: CollectionAttribute,
    ShellModel: ShellModel
  });

}).call(this);
