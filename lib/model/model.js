(function() {
  var Base, Binder, Model, Null, Varying, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  Base = require('../core/base').Base;

  Varying = require('../core/varying').Varying;

  util = require('../util/util');

  Binder = require('./binder').Binder;

  Null = {};

  Model = (function(_super) {
    __extends(Model, _super);

    function Model(attributes, options) {
      var binder;

      if (attributes == null) {
        attributes = {};
      }
      this.options = options != null ? options : {};
      Model.__super__.constructor.call(this);
      this.attributes = {};
      this._parent = this.options.parent;
      if (typeof this._initialize === "function") {
        this._initialize();
      }
      this.set(attributes);
      this._binders = (function() {
        var _i, _len, _ref, _results;

        _ref = this.constructor.binders();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          binder = _ref[_i];
          _results.push(binder.bind(this));
        }
        return _results;
      }).call(this);
    }

    Model.prototype.get = function(key) {
      var attribute, value, _ref;

      value = util.deepGet(this.attributes, key);
      if (value == null) {
        value = (_ref = this._parent) != null ? _ref.get(key) : void 0;
        if (value != null) {
          if (value instanceof Model) {
            value = this.set(key, value.shadow());
          } else if (value instanceof List) {
            value = this.set(key, new value.constructor(value.list));
          }
        }
      }
      if (value == null) {
        attribute = this.attribute(key);
        value = attribute != null ? attribute.writeDefault === true ? this.set(key, attribute["default"]()) : attribute["default"]() : void 0;
      }
      if (value == null) {
        value = null;
      }
      if (value === Null) {
        return null;
      } else {
        return value;
      }
    };

    Model.prototype.set = function() {
      var args, key, oldValue, value,
        _this = this;

      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (args.length === 1 && util.isPlainObject(args[0])) {
        return util.traverse(args[0], function(path, value) {
          return _this.set(path, value);
        });
      } else if (args.length === 2) {
        key = args[0], value = args[1];
        oldValue = util.deepGet(this.attributes, key);
        if (oldValue === value) {
          return value;
        }
        util.deepSet(this.attributes, key)(value === Null ? null : value);
        this._emitChange(key, value, oldValue);
        this.validate(key);
        return value;
      }
    };

    Model.prototype.unset = function(key) {
      var oldValue;

      oldValue = this.get(key);
      if (this._parent != null) {
        util.deepSet(this.attributes, key)(Null);
      } else {
        this._deleteAttr(key);
      }
      if (oldValue !== null) {
        this._emitChange(key, null, oldValue);
      }
      return oldValue;
    };

    Model.prototype.watch = function(key, transform) {
      var varying;

      varying = new Varying({
        value: this.get(key),
        transform: transform
      });
      return varying.listenTo(this, "changed:" + key, function(newValue) {
        return varying.setValue(newValue);
      });
    };

    Model.prototype.watchAll = function() {
      var varying,
        _this = this;

      varying = new Varying({
        value: this
      });
      return varying.listenTo(this, 'anyChanged', function() {
        return varying.setValue(_this, true);
      });
    };

    Model.attributes = function() {
      var _ref;

      return (_ref = this._attributes) != null ? _ref : this._attributes = {};
    };

    Model.attribute = function(key, attribute) {
      return this.attributes()[key] = attribute;
    };

    Model.prototype.attribute = function(key) {
      var _base;

      return typeof (_base = (this.constructor.attributes()[key])) === "function" ? new _base(this, key) : void 0;
    };

    Model.prototype.attributeClass = function(key) {
      return this.constructor.attributes()[key];
    };

    Model.binders = function() {
      var _ref;

      return (_ref = this._binders) != null ? _ref : this._binders = [];
    };

    Model.bind = function(key) {
      var binder;

      binder = new Binder(key);
      this.binders().push(binder);
      return binder;
    };

    Model.prototype.revert = function(key) {
      if (this._parent == null) {
        return;
      }
      return this._deleteAttr(key);
    };

    Model.prototype.shadow = function() {
      return new this.constructor({}, util.extendNew(this.options, {
        parent: this
      }));
    };

    Model.prototype.original = function() {
      var _ref;

      return (_ref = this._parent != null) != null ? _ref : this;
    };

    Model.prototype.merge = function() {
      var _ref;

      if ((_ref = this._parent) != null) {
        _ref.set(this.attributes);
      }
      return null;
    };

    Model.prototype.validate = function(key) {};

    Model.deserialize = function(data) {
      var attribute, key, prop, _ref;

      _ref = this.attributes();
      for (key in _ref) {
        attribute = _ref[key];
        prop = util.deepGet(data, key);
        if (prop != null) {
          util.deepSet(data, key)(attribute.deserialize(prop));
        }
      }
      return new this(data);
    };

    Model.serialize = function(model) {
      var result, walkAttrs,
        _this = this;

      walkAttrs = function(keys, src, target) {
        var attribute, result, strKey, subKey, thisKey, value;

        for (subKey in src) {
          value = src[subKey];
          thisKey = keys.concat([subKey]);
          strKey = thisKey.join('.');
          attribute = model.attribute(strKey);
          result = (attribute != null) && (attribute.serialize != null) ? attribute.serialize() : util.isPlainObject(value) ? (result = {}, walkAttrs(thisKey, value, result), util.hasProperties(result) ? result : void 0) : value;
          if (result instanceof Reference) {
            result = result.flatValue;
          }
          target[subKey] = result;
        }
        return target;
      };
      result = {};
      walkAttrs([], model.attributes, result);
      return result;
    };

    Model.prototype._deleteAttr = function(key) {
      var _this = this;

      return util.deepSet(this.attributes, key)(function(obj, subkey) {
        var newValue, oldValue;

        oldValue = obj[subkey];
        delete obj[subkey];
        newValue = _this.get(key);
        if (newValue !== oldValue) {
          _this._emitChange(key, newValue, oldValue);
        }
        return oldValue;
      });
    };

    Model.prototype._emitChange = function(key, newValue, oldValue) {
      var emit, parts,
        _this = this;

      parts = util.isArray(key) ? key : key.split('.');
      emit = function(name, partKey) {
        return _this.emit("" + name + ":" + partKey, newValue, oldValue, partKey);
      };
      emit('changed', parts.join('.'));
      while (parts.length > 1) {
        parts.pop();
        emit('subKeyChanged', parts.join('.'));
      }
      this.emit('anyChanged');
      return null;
    };

    return Model;

  })(Base);

  util.extend(module.exports, {
    Model: Model
  });

}).call(this);
