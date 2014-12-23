(function() {
  var Varying, build, caseSet, conj, defaultCases, from, ic, immediate, internalCases, mappedPoint, match, matchFinal, otherwise, terminus, val, _ref,
    __slice = [].slice;

  Varying = require('./varying').Varying;

  _ref = require('./case'), caseSet = _ref.caseSet, match = _ref.match, otherwise = _ref.otherwise;

  immediate = require('../util/util').immediate;

  conj = function(x, y) {
    return x.concat([y]);
  };

  internalCases = ic = caseSet('varying', 'map', 'flatMap');

  defaultCases = caseSet('dynamic', 'attr', 'definition', 'varying');

  val = function(conjunction, applicants) {
    var result;

    if (applicants == null) {
      applicants = [];
    }
    result = {};
    result.map = function(f) {
      var last, rest, _i;

      rest = 2 <= applicants.length ? __slice.call(applicants, 0, _i = applicants.length - 1) : (_i = 0, []), last = applicants[_i++];
      return val(conjunction, conj(rest, internalCases.map({
        inner: last,
        f: f
      })));
    };
    result.flatMap = function(f) {
      var last, rest, _i;

      rest = 2 <= applicants.length ? __slice.call(applicants, 0, _i = applicants.length - 1) : (_i = 0, []), last = applicants[_i++];
      return val(conjunction, conj(rest, internalCases.flatMap({
        inner: last,
        f: f
      })));
    };
    result.all = terminus(applicants);
    result.and = conjunction(applicants);
    return result;
  };

  build = function(cases) {
    var base, conjunction, kase, methods, name;

    methods = {};
    for (name in cases) {
      kase = cases[name];
      if (name !== 'dynamic' && name !== 'varying') {
        (function(name, kase) {
          return methods[name] = function(applicants) {
            return function() {
              var args;

              args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
              return val(conjunction, conj(applicants, kase(args)));
            };
          };
        })(name, kase);
      }
    }
    methods.varying = function(applicants) {
      return function(f) {
        return val(conjunction, conj(applicants, cases.varying(f)));
      };
    };
    base = cases.dynamic != null ? (function(applicants) {
      return function() {
        var args;

        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return val(conjunction, conj(applicants, cases.dynamic(args)));
      };
    }) : (function() {
      return {};
    });
    conjunction = function(applicants) {
      var k, result, v;

      if (applicants == null) {
        applicants = [];
      }
      result = base(applicants);
      for (k in methods) {
        v = methods[k];
        result[k] = v(applicants);
      }
      return result;
    };
    return conjunction();
  };

  mappedPoint = function(point) {
    return match(ic.map(function(_arg) {
      var f, inner;

      inner = _arg.inner, f = _arg.f;
      return match(ic.varying(function(x) {
        return ic.varying(x.map(f));
      }), otherwise(function() {
        return ic.map({
          inner: inner,
          f: f
        });
      }))(mappedPoint(point)(inner));
    }), ic.flatMap(function(_arg) {
      var f, inner;

      inner = _arg.inner, f = _arg.f;
      return match(ic.varying(function(x) {
        return ic.varying(x.flatMap(f));
      }), otherwise(function() {
        return ic.flatMap({
          inner: inner,
          f: f
        });
      }))(mappedPoint(point)(inner));
    }), ic.varying(function(x) {
      return ic.varying(x);
    }), otherwise(function(x) {
      var result;

      result = point(x);
      if ((result != null ? result.isVarying : void 0) === true) {
        return ic.varying(result);
      } else {
        return x;
      }
    }));
  };

  matchFinal = match(ic.varying(function(x) {
    return x;
  }), otherwise(function(x) {
    return new Varying(x);
  }));

  terminus = function(applicants) {
    var apply, result;

    apply = function(m) {
      return function(f) {
        var x;

        return m.apply(null, ((function() {
          var _i, _len, _results;

          _results = [];
          for (_i = 0, _len = applicants.length; _i < _len; _i++) {
            x = applicants[_i];
            _results.push(matchFinal(x));
          }
          return _results;
        })()).concat([f]));
      };
    };
    result = apply(Varying.flatMapAll);
    result.point = function(f) {
      var point, x;

      point = mappedPoint(f);
      return terminus((function() {
        var _i, _len, _results;

        _results = [];
        for (_i = 0, _len = applicants.length; _i < _len; _i++) {
          x = applicants[_i];
          _results.push(point(x));
        }
        return _results;
      })());
    };
    result.flatMap = apply(Varying.flatMapAll);
    result.map = apply(Varying.mapAll);
    return result;
  };

  from = build(defaultCases);

  from.build = build;

  from["default"] = defaultCases;

  module.exports = from;

}).call(this);
