(function() {
  var Base, Binder, Model, Null, Reference, Resolver, Varying, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  Base = require('../core/base').Base;

  Varying = require('../core/varying').Varying;

  _ref = require('./reference'), Reference = _ref.Reference, Resolver = _ref.Resolver;

  util = require('../util/util');

  Binder = require('./binder').Binder;

  Null = {};

  Model = (function(_super) {
    __extends(Model, _super);

    function Model(attributes, options) {
      if (attributes == null) {
        attributes = {};
      }
      this.options = options != null ? options : {};
      Model.__super__.constructor.call(this);
      this.attributes = {};
      this._attributes = {};
      this._watches = {};
      this._parent = this.options.parent;
      if (typeof this._preinitialize === "function") {
        this._preinitialize();
      }
      this.set(attributes);
      if (typeof this._initialize === "function") {
        this._initialize();
      }
      this._bind();
    }

    Model.prototype.get = function(key) {
      var attribute, value, _ref1;
      value = util.deepGet(this.attributes, key);
      if (value == null) {
        value = (_ref1 = this._parent) != null ? _ref1.get(key) : void 0;
        if (value instanceof Model) {
          value = this.set(key, value.shadow());
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
      if (this._parent != null) {
        oldValue = this.get(key);
        util.deepSet(this.attributes, key)(Null);
        if (oldValue !== null) {
          this._emitChange(key, null, oldValue);
        }
      } else {
        this._deleteAttr(key);
      }
      return oldValue;
    };

    Model.prototype.setAll = function(attrs) {
      var _this = this;
      util.traverseAll(this.attributes, function(path, value) {
        if (util.deepGet(attrs, path) == null) {
          return _this.unset(path.join('.'));
        }
      });
      this.set(attrs);
      return null;
    };

    Model.prototype.watch = function(key) {
      var _base,
        _this = this;
      return (_base = this._watches)[key] != null ? (_base = this._watches)[key] : _base[key] = (function() {
        var varying;
        varying = new Varying(_this.get(key));
        if (_this._parent != null) {
          varying.listenTo(_this._parent, "changed:" + key, function() {
            return varying.setValue(this.get(key));
          });
        }
        return varying.listenTo(_this, "changed:" + key, function(newValue) {
          return varying.setValue(newValue);
        });
      })();
    };

    Model.prototype.watchAll = function() {
      var varying,
        _this = this;
      varying = new Varying(this);
      return varying.listenTo(this, 'anyChanged', function() {
        return varying.setValue(_this, true);
      });
    };

    Model.attributes = function() {
      if (this._attributesAgainst !== this) {
        this._attributesAgainst = this;
        this._attributes = {};
      }
      return this._attributes;
    };

    Model.allAttributes = function() {
      var attrs, recurse,
        _this = this;

      attrs = {};
      recurse = function(obj) {
        var attr, key, _ref1;

        if (obj.attributes == null) {
          return;
        }
        if (obj.__super__ != null) {
          recurse(obj.__super__.constructor);
        }
        _ref1 = obj.attributes();
        for (key in _ref1) {
          attr = _ref1[key];
          attrs[key] = attr;
        }
        return null;
      };
      recurse(this);
      return attrs;
    };

    Model.attribute = function(key, attribute) {
      return this.attributes()[key] = attribute;
    };

    Model.prototype.attribute = function(key) {
      var recurse, _base,
        _this = this;
      recurse = function(obj) {
        var result, _base;
        if (obj.attributes == null) {
          return;
        }
        result = typeof (_base = (obj.attributes()[key])) === "function" ? new _base(_this, key) : void 0;
        if (result != null) {
          return result;
        } else if (obj.__super__ != null) {
          return recurse(obj.__super__.constructor);
        }
      };
      return (_base = this._attributes)[key] != null ? (_base = this._attributes)[key] : _base[key] = recurse(this.constructor);
    };

    Model.prototype.attributeClass = function(key) {
      return this.constructor.attributes()[key];
    };

    Model.binders = function() {
      if (this._bindersAgainst !== this) {
        this._bindersAgainst = this;
        this._binders = [];
      }
      return this._binders;
    };

    Model.bind = function(key) {
      var binder;
      binder = new Binder(key);
      this.binders().push(binder);
      return binder;
    };

    Model.prototype._bind = function() {
      var recurse,
        _this = this;
      this._binders = {};
      recurse = function(obj) {
        var binder, _i, _len, _ref1;
        _ref1 = obj.binders();
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          binder = _ref1[_i];
          if (_this._binders[binder._key] == null) {
            _this._binders[binder._key] = binder.bind(_this);
          }
        }
        if ((obj.__super__ != null) && (obj.__super__.constructor.binders != null)) {
          recurse(obj.__super__.constructor);
        }
        return null;
      };
      recurse(this.constructor);
      return null;
    };

    Model.prototype.rebind = function(key) {
      var _ref1;
      return (_ref1 = this._binders[key]) != null ? _ref1.apply() : void 0;
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

    Model.prototype.modified = function(deep) {
      var result,
        _this = this;
      if (deep == null) {
        deep = true;
      }
      if (this._parent == null) {
        return false;
      }
      result = false;
      util.traverse(this.attributes, function(path, value) {
        var attribute, parentValue;
        attribute = _this.attribute(path);
        if ((attribute == null) || attribute.transient === false) {
          parentValue = _this._parent.get(path);
          if (value instanceof Model) {
            if (deep === true) {
              return result = result || value.modified();
            } else {
              return result = result || parentValue !== value._parent;
            }
          } else {
            if (value === Null) {
              value = null;
            }
            if (parentValue !== value && !((parentValue == null) && (value == null))) {
              return result = true;
            }
          }
        }
      });
      return result;
    };

    Model.prototype.original = function() {
      var _ref1;
      return (_ref1 = this._parent != null) != null ? _ref1 : this;
    };

    Model.prototype.merge = function() {
      var _ref1;
      if ((_ref1 = this._parent) != null) {
        _ref1.set(this.attributes);
      }
      return null;
    };

    Model.prototype.validate = function(key) {};

    Model.deserialize = function(data) {
      var attribute, key, prop, _ref1;
      _ref1 = this.allAttributes();
      for (key in _ref1) {
        attribute = _ref1[key];
        prop = util.deepGet(data, key);
        if (prop != null) {
          util.deepSet(data, key)(attribute.deserialize(prop));
        }
      }
      return new this(data);
    };

    Model.serialize = function(model, opts) {
      if (opts == null) {
        opts = {};
      }
      return this._plainObject('serialize', model, opts);
    };

    Model.prototype.serialize = function() {
      return this.constructor.serialize(this);
    };

    Model._plainObject = function(method, model, opts) {
      var result, walkAttrs,
        _this = this;
      if (opts == null) {
        opts = {};
      }
      if (model == null) {
        return null;
      }
      walkAttrs = function(keys, src, target) {
        var attribute, innerResult, result, strKey, subKey, thisKey, value, _ref1;
        for (subKey in src) {
          value = src[subKey];
          thisKey = keys.concat([subKey]);
          strKey = thisKey.join('.');
          attribute = model.attribute(strKey);
          result = value === Null ? void 0 : (attribute != null) && (attribute[method] != null) ? attribute[method](opts) : util.isPlainObject(value) ? (innerResult = (_ref1 = target[subKey]) != null ? _ref1 : {}, walkAttrs(thisKey, value, innerResult), innerResult) : value;
          if (result instanceof Reference) {
            result = result.flatValue;
          }
          target[subKey] = result;
        }
        return target;
      };
      result = model._parent != null ? Model[method](model._parent, opts) : {};
      walkAttrs([], model.attributes, result);
      return result;
    };

    Model.extract = function(model, f, opts) {
      return f(this._extract(model, opts));
    };

    Model._extract = function(model, opts) {
      return this._plainObject('_extract', model, opts);
    };

    Model.prototype.extract = function(f, opts) {
      return this.constructor.extract(this, f, opts);
    };

    Model.prototype._extract = function(opts) {
      return this.constructor._extract(this, opts);
    };

    Model.prototype._deleteAttr = function(key) {
      var _this = this;
      return util.deepSet(this.attributes, key)(function(obj, subkey) {
        var newValue, oldValue;
        if (obj == null) {
          return;
        }
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
