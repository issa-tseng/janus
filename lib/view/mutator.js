(function() {
  var AttrMutator, ClassGroupMutator, ClassMutator, CssMutator, HtmlMutator, Mutator, Mutator0, Mutator1, RenderMutator, TextMutator, Varying, attr, caseSet, classGroup, classed, css, extendNew, from, html, identity, isPrimitive, match, mutators, operations, otherwise, promote, render, safe, text, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Varying = require('../core/varying').Varying;

  _ref = require('../util/util'), isPrimitive = _ref.isPrimitive, extendNew = _ref.extendNew, identity = _ref.identity;

  from = require('../core/from');

  _ref1 = require('../core/case'), caseSet = _ref1.caseSet, match = _ref1.match, otherwise = _ref1.otherwise;

  _ref2 = operations = caseSet('attr', 'classGroup', 'classed', 'css', 'text', 'html', 'render'), attr = _ref2.attr, classGroup = _ref2.classGroup, classed = _ref2.classed, css = _ref2.css, text = _ref2.text, html = _ref2.html, render = _ref2.render;

  safe = function(x) {
    if (isPrimitive(x)) {
      return x.toString();
    } else {
      return '';
    }
  };

  promote = function(x) {
    if (x.react != null) {
      return x;
    } else if (x.all != null) {
      return promote(x.all);
    }
  };

  Mutator = (function() {
    function Mutator(binding) {
      this._bindings = [binding];
    }

    Mutator.prototype.bind = function(artifact) {
      this._artifact = artifact;
      this._start();
      return null;
    };

    Mutator.prototype.point = function(point, app) {
      this._point = point;
      this._app = app;
      this._start();
      return null;
    };

    Mutator.prototype._start = function() {
      var binding, pointed,
        _this = this;

      this.stop();
      if (this._artifact == null) {
        return;
      }
      pointed = (function() {
        var _i, _len, _ref3, _ref4, _results;

        _ref3 = this.bindings();
        _results = [];
        for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
          binding = _ref3[_i];
          _results.push(promote(binding).point((_ref4 = this._point) != null ? _ref4 : (function() {
            return new Varying();
          })));
        }
        return _results;
      }).call(this);
      this._bound = Varying.flatMapAll.apply(null, pointed.concat([this.exec()])).reactNow(function(f) {
        return f(_this._artifact, _this._app);
      });
      return null;
    };

    Mutator.prototype.stop = function() {
      var _ref3;

      if ((_ref3 = this._bound) != null) {
        _ref3.stop();
      }
      return null;
    };

    Mutator.prototype.bindings = function() {
      return this._bindings;
    };

    Mutator.prototype.exec = function() {
      return this.constructor.exec;
    };

    Mutator.exec = function() {};

    return Mutator;

  })();

  Mutator0 = Mutator;

  Mutator1 = (function(_super) {
    __extends(Mutator1, _super);

    function Mutator1(_param, binding) {
      this._param = _param;
      Mutator1.__super__.constructor.call(this, binding);
    }

    Mutator1.prototype.exec = function() {
      return this.constructor.exec(this._param);
    };

    return Mutator1;

  })(Mutator);

  mutators = {
    attr: AttrMutator = (function(_super) {
      __extends(AttrMutator, _super);

      function AttrMutator() {
        _ref3 = AttrMutator.__super__.constructor.apply(this, arguments);
        return _ref3;
      }

      AttrMutator.exec = function(attr) {
        return function(x) {
          return function(dom) {
            return dom.attr(attr, safe(x));
          };
        };
      };

      return AttrMutator;

    })(Mutator1),
    classGroup: ClassGroupMutator = (function(_super) {
      __extends(ClassGroupMutator, _super);

      function ClassGroupMutator() {
        _ref4 = ClassGroupMutator.__super__.constructor.apply(this, arguments);
        return _ref4;
      }

      ClassGroupMutator.exec = function(prefix) {
        return function(x) {
          return function(dom) {
            var className, existing, _i, _len, _ref5, _ref6;

            existing = (_ref5 = (_ref6 = dom.attr('class')) != null ? _ref6.split(' ') : void 0) != null ? _ref5 : [];
            for (_i = 0, _len = existing.length; _i < _len; _i++) {
              className = existing[_i];
              if (className.indexOf(prefix) === 0) {
                dom.removeClass(className);
              }
            }
            if (isPrimitive(x) === true) {
              return dom.addClass("" + prefix + x);
            }
          };
        };
      };

      return ClassGroupMutator;

    })(Mutator1),
    classed: ClassMutator = (function(_super) {
      __extends(ClassMutator, _super);

      function ClassMutator() {
        _ref5 = ClassMutator.__super__.constructor.apply(this, arguments);
        return _ref5;
      }

      ClassMutator.exec = function(className) {
        return function(x) {
          return function(dom) {
            return dom.toggleClass(className, x === true);
          };
        };
      };

      return ClassMutator;

    })(Mutator1),
    css: CssMutator = (function(_super) {
      __extends(CssMutator, _super);

      function CssMutator() {
        _ref6 = CssMutator.__super__.constructor.apply(this, arguments);
        return _ref6;
      }

      CssMutator.exec = function(prop) {
        return function(x) {
          return function(dom) {
            return dom.css(prop, safe(x));
          };
        };
      };

      return CssMutator;

    })(Mutator1),
    text: TextMutator = (function(_super) {
      __extends(TextMutator, _super);

      function TextMutator() {
        _ref7 = TextMutator.__super__.constructor.apply(this, arguments);
        return _ref7;
      }

      TextMutator.exec = function(x) {
        return function(dom) {
          return dom.text(safe(x));
        };
      };

      return TextMutator;

    })(Mutator0),
    html: HtmlMutator = (function(_super) {
      __extends(HtmlMutator, _super);

      function HtmlMutator() {
        _ref8 = HtmlMutator.__super__.constructor.apply(this, arguments);
        return _ref8;
      }

      HtmlMutator.exec = function(x) {
        return function(dom) {
          return dom.html(safe(x));
        };
      };

      return HtmlMutator;

    })(Mutator0),
    render: RenderMutator = (function(_super) {
      __extends(RenderMutator, _super);

      function RenderMutator(subject, bindings) {
        if (bindings == null) {
          bindings = {};
        }
        this._bindings = bindings.subject != null ? extendNew(bindings, {
          subject: subject
        }) : bindings;
      }

      RenderMutator.prototype.context = function(context) {
        return new RenderMutator(this._bindings.subject, extendNew(bindings, {
          context: context
        }));
      };

      RenderMutator.prototype.library = function(library) {
        return new RenderMutator(this._bindings.subject, extendNew(bindings, {
          library: library
        }));
      };

      RenderMutator.prototype.options = function(options) {
        return new RenderMutator(this._bindings.subject, extendNew(bindings, {
          options: options
        }));
      };

      RenderMutator.prototype.start = function() {
        var binding, finalBinding, name, pointedBindings, _ref9,
          _this = this;

        this.stop();
        pointedBindings = {};
        _ref9 = this._bindings;
        for (name in _ref9) {
          binding = _ref9[name];
          pointedBindings.name = binding.point != null ? binding.point(this._point) : Varying.ly(binding);
        }
        finalBinding = Varying.pure(this.constructor.exec, pointedBindings.subject, pointedBindings.context, pointedBindings.library, pointedBindings.options);
        return this._boundings = [
          finalBinding.reactNow(function(f) {
            return f(_this._artifact, _this._app);
          })
        ];
      };

      RenderMutator.exec = function(subject, context, library, options) {
        return function(dom, app) {
          var view, _base, _ref10, _ref9;

          view = typeof (_base = (_ref9 = library != null ? library.get : void 0) != null ? _ref9 : app != null ? app.getView : void 0) === "function" ? _base(subject, util.extendNew(options != null ? options : {}, {
            context: context
          })) : void 0;
          if ((_ref10 = dom.data('subview')) != null) {
            _ref10.destroy();
          }
          dom.empty();
          if (view != null) {
            dom.append(view.artifact());
          }
          return dom.data('subview', view);
        };
      };

      return RenderMutator;

    })(Mutator)
  };

  module.exports = {
    Mutator: Mutator,
    mutators: mutators,
    _internal: {
      Mutator1: Mutator1
    }
  };

}).call(this);
