(function() {
  var ApplyMutator, AttrMutator, Base, Binder, ClassGroupMutator, ClassMutator, CssMutator, HtmlMutator, MultiVarying, Mutator, RenderMutator, RenderWithMutator, TextMutator, Varying, traverseFrom, types, util, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  util = require('../util/util');

  Base = require('../core/base').Base;

  _ref = require('../core/varying'), Varying = _ref.Varying, MultiVarying = _ref.MultiVarying;

  types = require('./types');

  Binder = (function(_super) {
    __extends(Binder, _super);

    function Binder(dom, options) {
      this.dom = dom;
      this.options = options;
      Binder.__super__.constructor.call(this);
      this._children = {};
      this._mutatorIndex = {};
      this._mutators = [];
    }

    Binder.prototype.find = function(selector) {
      var _base, _ref1;

      return (_ref1 = (_base = this._children)[selector]) != null ? _ref1 : _base[selector] = new Binder(this.dom.find(selector), {
        parent: this
      });
    };

    Binder.prototype.classed = function(className) {
      return this._attachMutator(ClassMutator, [className]);
    };

    Binder.prototype.classGroup = function(classPrefix) {
      return this._attachMutator(ClassGroupMutator, [classPrefix]);
    };

    Binder.prototype.attr = function(attrName) {
      return this._attachMutator(AttrMutator, [attrName]);
    };

    Binder.prototype.css = function(cssAttr) {
      return this._attachMutator(CssMutator, [cssAttr]);
    };

    Binder.prototype.text = function() {
      return this._attachMutator(TextMutator);
    };

    Binder.prototype.html = function() {
      return this._attachMutator(HtmlMutator);
    };

    Binder.prototype.render = function(app, options) {
      return this._attachMutator(RenderMutator, [app, options]);
    };

    Binder.prototype.renderWith = function(klass, options) {
      return this._attachMutator(RenderWithMutator, [klass, options]);
    };

    Binder.prototype.apply = function(f) {
      return this._attachMutator(ApplyMutator, [f]);
    };

    Binder.prototype.from = function(dataObj, dataKey) {
      return this.text().from(dataObj, dataKey);
    };

    Binder.prototype.fromVarying = function(func) {
      return this.text().fromVarying(func);
    };

    Binder.prototype.end = function() {
      return this.options.parent;
    };

    Binder.prototype.data = function(primary, aux) {
      var child, mutator, _, _i, _len, _ref1, _ref2;

      _ref1 = this._children;
      for (_ in _ref1) {
        child = _ref1[_];
        child.data(primary, aux);
      }
      _ref2 = this._mutators;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        mutator = _ref2[_i];
        mutator.data(primary, aux);
      }
      return null;
    };

    Binder.prototype._attachMutator = function(klass, param) {
      var existingMutator, identity, mutator, _base, _name, _ref1;

      identity = klass.identity(param);
      existingMutator = ((_ref1 = (_base = this._mutatorIndex)[_name = klass.name]) != null ? _ref1 : _base[_name] = {})[identity];
      mutator = new klass(this.dom, this, param, existingMutator);
      mutator.destroyWith(this);
      this._mutatorIndex[klass.name][identity] = mutator;
      this._mutators.push(mutator);
      return mutator;
    };

    return Binder;

  })(Base);

  Mutator = (function(_super) {
    __extends(Mutator, _super);

    function Mutator(dom, parentBinder, params, parentMutator) {
      var _ref1;

      this.dom = dom;
      this.parentBinder = parentBinder;
      this.params = params;
      this.parentMutator = parentMutator;
      Mutator.__super__.constructor.call(this);
      this._data = [];
      this._listeners = [];
      this._fallback = this._transform = this._value = null;
      if ((_ref1 = this._parentMutator) != null) {
        _ref1._isParent = true;
      }
      if (typeof this._namedParams === "function") {
        this._namedParams(this.params);
      }
      if (typeof this._initialize === "function") {
        this._initialize();
      }
    }

    Mutator.prototype.from = function() {
      var path,
        _this = this;

      path = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this._data.push(function(primary) {
        return _this._from(primary, path);
      });
      return this;
    };

    Mutator.prototype.fromSelf = function() {
      this._data.push(function(primary) {
        return new Varying({
          value: primary
        });
      });
      return this;
    };

    Mutator.prototype.fromAux = function() {
      var key, path,
        _this = this;

      key = arguments[0], path = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      this._data.push(function(_, aux) {
        return _this._from(util.deepGet(aux, key), path);
      });
      return this;
    };

    Mutator.prototype.fromAttribute = function(key) {
      this._data.push(function(primary) {
        return new Varying({
          value: primary.attribute(key)
        });
      });
      return this;
    };

    Mutator.prototype._from = function(obj, path) {
      var next;

      next = function(idx) {
        return function(result) {
          if (path[idx + 1] != null) {
            return result != null ? result.watch(path[idx], next(idx + 1)) : void 0;
          } else {
            return result != null ? result.watch(path[idx]) : void 0;
          }
        };
      };
      return next(0)(obj);
    };

    Mutator.prototype.fromVarying = function(varyingGenerator) {
      this._data.push(function(primary, aux) {
        return varyingGenerator(primary, aux);
      });
      return this;
    };

    Mutator.prototype.and = Mutator.prototype.from;

    Mutator.prototype.andAux = Mutator.prototype.fromAux;

    Mutator.prototype.andVarying = Mutator.prototype.fromVarying;

    Mutator.prototype.andLast = function() {
      var _this = this;

      this._data.push(function() {
        _this.parentMutator.data(primary, aux);
        return _this.parentMutator._varying;
      });
      return this;
    };

    Mutator.prototype.transform = function(transform) {
      this._transform = transform;
      return this;
    };

    Mutator.prototype.flatMap = Mutator.prototype.transform;

    Mutator.prototype.fallback = function(fallback) {
      this._fallback = fallback;
      return this;
    };

    Mutator.prototype.data = function(primary, aux) {
      var datum, listener, process, _i, _len, _ref1,
        _this = this;

      _ref1 = this._listeners;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        listener = _ref1[_i];
        listener.destroy();
      }
      this._listeners = (function() {
        var _j, _len1, _ref2, _results;

        _ref2 = this._data;
        _results = [];
        for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
          datum = _ref2[_j];
          _results.push(datum(primary, aux));
        }
        return _results;
      }).call(this);
      process = function() {
        var values;

        values = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (_this._transform != null) {
          return _this._transform.apply(_this, values);
        } else if (values.length === 1) {
          return values[0];
        } else {
          return values;
        }
      };
      this._varying = new MultiVarying(this._listeners, process);
      this._varying.destroyWith(this);
      this._varying.on('changed', function() {
        return _this.apply();
      });
      if (this.parentBinder.options.bindOnly !== true) {
        this.apply();
      }
      return this;
    };

    Mutator.prototype.calculate = function() {
      var _ref1, _ref2;

      return (_ref1 = (_ref2 = this._varying) != null ? _ref2.value : void 0) != null ? _ref1 : this._fallback;
    };

    Mutator.prototype.apply = function() {
      if (!this._isParent) {
        return this._apply(this.calculate());
      }
    };

    Mutator.prototype.end = function() {
      return this.parentBinder;
    };

    Mutator.identity = function() {
      return util.uniqueId();
    };

    Mutator.prototype._apply = function() {};

    return Mutator;

  })(Base);

  traverseFrom = function(obj, path, transform) {};

  ClassMutator = (function(_super) {
    __extends(ClassMutator, _super);

    function ClassMutator() {
      _ref1 = ClassMutator.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    ClassMutator.identity = function(_arg) {
      var className;

      className = _arg[0];
      return className;
    };

    ClassMutator.prototype._namedParams = function(_arg) {
      this.className = _arg[0];
    };

    ClassMutator.prototype._apply = function(bool) {
      return this.dom.toggleClass(this.className, bool != null ? bool : false);
    };

    return ClassMutator;

  })(Mutator);

  ClassGroupMutator = (function(_super) {
    __extends(ClassGroupMutator, _super);

    function ClassGroupMutator() {
      _ref2 = ClassGroupMutator.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    ClassGroupMutator.identity = function(_arg) {
      var classPrefix;

      classPrefix = _arg[0];
      return classPrefix;
    };

    ClassGroupMutator.prototype._namedParams = function(_arg) {
      this.classPrefix = _arg[0];
    };

    ClassGroupMutator.prototype._apply = function(value) {
      var className, existingClasses, _i, _len, _ref3;

      existingClasses = (_ref3 = this.dom.attr('class')) != null ? _ref3.split(' ') : void 0;
      if (existingClasses != null) {
        for (_i = 0, _len = existingClasses.length; _i < _len; _i++) {
          className = existingClasses[_i];
          if (className.indexOf(this.classPrefix) === 0) {
            this.dom.removeClass(className);
          }
        }
      }
      if (value != null) {
        return this.dom.addClass("" + this.classPrefix + value);
      }
    };

    return ClassGroupMutator;

  })(Mutator);

  AttrMutator = (function(_super) {
    __extends(AttrMutator, _super);

    function AttrMutator() {
      _ref3 = AttrMutator.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    AttrMutator.identity = function(_arg) {
      var attr;

      attr = _arg[0];
      return attr;
    };

    AttrMutator.prototype._namedParams = function(_arg) {
      this.attr = _arg[0];
    };

    AttrMutator.prototype._apply = function(value) {
      return this.dom.attr(this.attr, value);
    };

    return AttrMutator;

  })(Mutator);

  CssMutator = (function(_super) {
    __extends(CssMutator, _super);

    function CssMutator() {
      _ref4 = CssMutator.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    CssMutator.identity = function(_arg) {
      var cssAttr;

      cssAttr = _arg[0];
      return cssAttr;
    };

    CssMutator.prototype._namedParams = function(_arg) {
      this.cssAttr = _arg[0];
    };

    CssMutator.prototype._apply = function(value) {
      return this.dom.css(this.cssAttr, value);
    };

    return CssMutator;

  })(Mutator);

  TextMutator = (function(_super) {
    __extends(TextMutator, _super);

    function TextMutator() {
      _ref5 = TextMutator.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    TextMutator.identity = function() {
      return 'text';
    };

    TextMutator.prototype._apply = function(text) {
      var _ref6;

      return this.dom.text((_ref6 = text != null ? text.toString() : void 0) != null ? _ref6 : '');
    };

    return TextMutator;

  })(Mutator);

  HtmlMutator = (function(_super) {
    __extends(HtmlMutator, _super);

    function HtmlMutator() {
      _ref6 = HtmlMutator.__super__.constructor.apply(this, arguments);
      return _ref6;
    }

    HtmlMutator.identity = function() {
      return 'html';
    };

    HtmlMutator.prototype._apply = function(html) {
      return this.dom.html(html);
    };

    return HtmlMutator;

  })(Mutator);

  RenderMutator = (function(_super) {
    __extends(RenderMutator, _super);

    function RenderMutator() {
      _ref7 = RenderMutator.__super__.constructor.apply(this, arguments);
      return _ref7;
    }

    RenderMutator.prototype._initialize = function() {
      var _base, _ref8, _ref9;

      if ((_ref8 = this.options) == null) {
        this.options = {};
      }
      if ((_ref9 = (_base = this.options).constructorOpts) == null) {
        _base.constructorOpts = {};
      }
      return this.options = util.extendNew(this.options, {
        constructorOpts: util.extendNew({
          bindOnly: this.parentBinder.options.bindOnly
        }, this.options.constructorOpts)
      });
    };

    RenderMutator.prototype._namedParams = function(_arg) {
      this.app = _arg[0], this.options = _arg[1];
    };

    RenderMutator.prototype._apply = function(result) {
      var klass, lastKlass, _ref8;

      lastKlass = this._lastKlass;
      delete this._lastKlass;
      if (result == null) {
        return this._clear();
      } else if (result instanceof types.WithOptions) {
        klass = this.app.getView(result.model, util.extendNew(result.options, {
          handler: function(_) {
            return _;
          }
        }));
        if (klass === lastKlass) {
          return;
        }
        this._lastKlass = klass;
        return this._render(new klass(result.model, (_ref8 = this.options) != null ? _ref8.constructorOpts : void 0));
      } else if (result instanceof types.WithView) {
        return this._render(result.view);
      } else {
        return this._render(this.app.getView(result, this.options));
      }
    };

    RenderMutator.prototype._render = function(view) {
      this._clear();
      this._lastView = view;
      this.dom.empty();
      if (view != null) {
        view.destroyWith(this);
        return this.dom.append(view.artifact());
      }
    };

    RenderMutator.prototype._clear = function() {
      if (this._lastView != null) {
        return this._lastView.destroy();
      }
    };

    return RenderMutator;

  })(Mutator);

  RenderWithMutator = (function(_super) {
    __extends(RenderWithMutator, _super);

    function RenderWithMutator() {
      _ref8 = RenderWithMutator.__super__.constructor.apply(this, arguments);
      return _ref8;
    }

    RenderWithMutator.prototype._namedParams = function(_arg) {
      this.klass = _arg[0], this.options = _arg[1];
    };

    RenderWithMutator.prototype._apply = function(model) {
      return this.dom.empty().append(new this.klass(model, this.options));
    };

    return RenderWithMutator;

  })(Mutator);

  ApplyMutator = (function(_super) {
    __extends(ApplyMutator, _super);

    function ApplyMutator() {
      _ref9 = ApplyMutator.__super__.constructor.apply(this, arguments);
      return _ref9;
    }

    ApplyMutator.prototype._namedParams = function(_arg) {
      this.f = _arg[0];
    };

    ApplyMutator.prototype._apply = function(value) {
      return this.f(this.dom, value);
    };

    return ApplyMutator;

  })(Mutator);

  util.extend(module.exports, {
    Binder: Binder,
    Mutator: Mutator,
    mutators: {
      ClassMutator: ClassMutator,
      ClassGroupMutator: ClassGroupMutator,
      AttrMutator: AttrMutator,
      CssMutator: CssMutator,
      TextMutator: TextMutator,
      HtmlMutator: HtmlMutator,
      RenderMutator: RenderMutator,
      RenderWithMutator: RenderWithMutator,
      ApplyMutator: ApplyMutator
    }
  });

}).call(this);
