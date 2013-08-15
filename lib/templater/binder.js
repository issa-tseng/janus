(function() {
  var ApplyMutator, AttrMutator, Base, Binder, ClassGroupMutator, ClassMutator, CssMutator, HtmlMutator, MultiVarying, Mutator, RenderMutator, RenderWithMutator, TextMutator, Varying, reference, types, util, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  util = require('../util/util');

  Base = require('../core/base').Base;

  _ref = require('../core/varying'), Varying = _ref.Varying, MultiVarying = _ref.MultiVarying;

  types = require('./types');

  reference = require('../model/reference');

  Binder = (function(_super) {
    __extends(Binder, _super);

    function Binder(dom, options) {
      this.dom = dom;
      this.options = options != null ? options : {};
      Binder.__super__.constructor.call(this);
      this._children = {};
      this._mutatorIndex = {};
      this._mutators = [];
    }

    Binder.prototype.find = function(selector) {
      var _base, _ref1;

      return (_ref1 = (_base = this._children)[selector]) != null ? _ref1 : _base[selector] = new Binder(this.dom.find(selector), util.extendNew(this.options, {
        parent: this
      }));
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

    Binder.prototype.from = function() {
      var path, _ref1;

      path = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return (_ref1 = this.text()).from.apply(_ref1, path);
    };

    Binder.prototype.fromVarying = function(func) {
      return this.text().fromVarying(func);
    };

    Binder.prototype.end = function() {
      return this.options.parent;
    };

    Binder.prototype.data = function(primary, aux, shouldRender) {
      var child, mutator, _, _i, _len, _ref1, _ref2;

      _ref1 = this._children;
      for (_ in _ref1) {
        child = _ref1[_];
        child.data(primary, aux, shouldRender);
      }
      _ref2 = this._mutators;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        mutator = _ref2[_i];
        mutator.data(primary, aux, shouldRender);
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
      this._fallback = this._flatMap = this._value = null;
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
        return new Varying(primary);
      });
      return this;
    };

    Mutator.prototype.fromAux = function() {
      var key, path,
        _this = this;

      key = arguments[0], path = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if ((path != null) && path.length > 0) {
        this._data.push(function(_, aux) {
          return _this._from(util.deepGet(aux, key), path);
        });
      } else {
        this._data.push(function(_, aux) {
          return new Varying(util.deepGet(aux, key));
        });
      }
      return this;
    };

    Mutator.prototype.fromAttribute = function(key) {
      this._data.push(function(primary) {
        return new Varying(primary.attribute(key));
      });
      return this;
    };

    Mutator.prototype._from = function(obj, path) {
      var next, results,
        _this = this;

      results = [];
      next = function(idx) {
        return function(result) {
          var resolved;

          results[idx] = result;
          if (result instanceof reference.RequestResolver) {
            resolved = result.resolve(_this.parentBinder.options.app);
            if (resolved != null) {
              return next(0)(obj);
            }
          } else if (result instanceof reference.ModelResolver) {
            resolved = result.resolve(results[idx - 1]);
            if (resolved != null) {
              return next(0)(obj);
            }
          } else if (idx < path.length) {
            if ((result != null) && (result.watch == null)) {
              debugger;
            }
            return result != null ? result.watch(path[idx]).map(next(idx + 1)) : void 0;
          } else {
            return result;
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

    Mutator.prototype.andSelf = Mutator.prototype.fromSelf;

    Mutator.prototype.andAux = Mutator.prototype.fromAux;

    Mutator.prototype.andAttribute = Mutator.prototype.fromAttribute;

    Mutator.prototype.andVarying = Mutator.prototype.fromVarying;

    Mutator.prototype.andLast = function() {
      var _this = this;

      this._data.push(function() {
        _this.parentMutator.data(primary, aux);
        return _this.parentMutator._varying;
      });
      return this;
    };

    Mutator.prototype.flatMap = function(f) {
      this._flatMap = f;
      return this;
    };

    Mutator.prototype.fallback = function(fallback) {
      this._fallback = fallback;
      return this;
    };

    Mutator.prototype.data = function(primary, aux, shouldRender) {
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
        if (_this._flatMap != null) {
          return _this._flatMap.apply(_this, values);
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
      this.apply(shouldRender);
      shouldRender = true;
      return this;
    };

    Mutator.prototype.calculate = function() {
      var _ref1, _ref2;

      return (_ref1 = (_ref2 = this._varying) != null ? _ref2.value : void 0) != null ? _ref1 : this._fallback;
    };

    Mutator.prototype.apply = function(shouldRender) {
      if (shouldRender == null) {
        shouldRender = true;
      }
      if (!(shouldRender === true ? this._isParent : void 0)) {
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
      if ((value != null) && util.isString(value)) {
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
      return this.dom.attr(this.attr, util.isPrimitive(value) ? value : '');
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
      return this.dom.css(this.cssAttr, util.isPrimitive(value) ? value : '');
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
      return this.dom.text(util.isPrimitive(text) ? text.toString() : '');
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
      return this.dom.html(util.isPrimitive(html) ? html.tString() : '');
    };

    return HtmlMutator;

  })(Mutator);

  RenderMutator = (function(_super) {
    __extends(RenderMutator, _super);

    function RenderMutator() {
      _ref7 = RenderMutator.__super__.constructor.apply(this, arguments);
      return _ref7;
    }

    RenderMutator.prototype._namedParams = function(_arg) {
      this.app = _arg[0], this.options = _arg[1];
    };

    RenderMutator.prototype.apply = function(shouldRender) {
      if (shouldRender == null) {
        shouldRender = true;
      }
      if (!this._isParent) {
        return this._render(this._viewFromResult(this.calculate()), shouldRender);
      }
    };

    RenderMutator.prototype._viewFromResult = function(result) {
      var constructorOpts, lastKlass;

      lastKlass = this._lastKlass;
      delete this._lastKlass;
      if (result == null) {
        return null;
      } else if (result instanceof types.WithOptions) {
        return this.app.getView(result.model, result.options);
      } else if (result instanceof types.WithView) {
        return result.view;
      } else if (result instanceof types.WithAux && (result.primary != null)) {
        constructorOpts = util.extendNew(this.options.constructorOpts, {
          aux: result.aux
        });
        return this.app.getView(result.primary, util.extendNew(this.options, {
          constructorOpts: constructorOpts
        }));
      } else {
        return this.app.getView(result, this.options);
      }
    };

    RenderMutator.prototype._render = function(view, shouldRender) {
      this._clear();
      this._lastView = view;
      this.dom.empty();
      if (view != null) {
        view.destroyWith(this);
        if (shouldRender === true) {
          this.dom.append(view.artifact());
          return view.emit('appended');
        } else {
          return view.bind(this.dom.contents());
        }
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
