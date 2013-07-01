(function() {
  var Base, Indefinite, IndefiniteList, Many, One, OrderedIncrementalList, StepResult, Termination, Varying, util, _ref, _ref1,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Base = require('../core/base').Base;

  OrderedIncrementalList = require('./types').OrderedIncrementalList;

  Varying = require('../core/varying').Varying;

  util = require('../util/util');

  StepResult = (function() {
    function StepResult() {}

    return StepResult;

  })();

  One = (function(_super) {
    __extends(One, _super);

    function One(elem, step) {
      this.elem = elem;
      this.step = step;
    }

    return One;

  })(StepResult);

  Many = (function(_super) {
    __extends(Many, _super);

    function Many(elems, step) {
      this.elems = elems;
      this.step = step;
    }

    return Many;

  })(StepResult);

  Indefinite = (function(_super) {
    __extends(Indefinite, _super);

    function Indefinite() {
      _ref = Indefinite.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    return Indefinite;

  })(StepResult);

  Termination = (function(_super) {
    __extends(Termination, _super);

    function Termination() {
      _ref1 = Termination.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    return Termination;

  })(StepResult);

  IndefiniteList = (function(_super) {
    __extends(IndefiniteList, _super);

    function IndefiniteList(step, options) {
      this.options = options != null ? options : {};
      IndefiniteList.__super__.constructor.call(this);
      this.list = [];
      this._step(step, 0);
    }

    IndefiniteList.prototype.at = function(idx) {
      return this.list[idx];
    };

    IndefiniteList.prototype._step = function(step, idx) {
      var process, result,
        _this = this;

      result = step();
      process = function(result) {
        var elem, subidx, _base, _i, _len, _ref2;

        _this._truncate(idx);
        if (result instanceof One) {
          _this.list.push(result.elem);
          _this.emit('added', result.elem, idx);
          if (typeof (_base = result.elem).emit === "function") {
            _base.emit('addedTo', _this, idx);
          }
          return _this._step(result.step, idx + 1);
        } else if (result instanceof Many) {
          _this.list = _this.list.concat(result.elems);
          _ref2 = result.elems;
          for (subidx = _i = 0, _len = _ref2.length; _i < _len; subidx = ++_i) {
            elem = _ref2[subidx];
            _this.emit('added', elem, idx + subidx);
            if (typeof elem.emit === "function") {
              elem.emit('addedTo', _this, idx + subidx);
            }
          }
          return _this._step(result.step, idx + result.elems.length);
        } else if (result instanceof Indefinite) {
          return _this.set('completion', Indefinite);
        } else if (result instanceof Termination) {
          return _this.set('completion', Termination);
        }
      };
      if (result instanceof Varying) {
        result.on('changed', function(newResult) {
          return process(newResult);
        });
        return process(result.value);
      } else {
        return process(result);
      }
    };

    IndefiniteList.prototype._truncate = function(idx) {
      var elem, removed, subidx, _i, _len;

      removed = this.list.slice(idx);
      this.list = this.list.slice(0, idx);
      for (subidx = _i = 0, _len = removed.length; _i < _len; subidx = ++_i) {
        elem = removed[subidx];
        this.emit('removed', elem, idx + subidx);
        if (typeof elem.emit === "function") {
          elem.emit('removedFrom', this, idx + subidx);
        }
      }
      return null;
    };

    IndefiniteList.One = function(elem, step) {
      return new One(elem, step);
    };

    IndefiniteList.Many = function(elems, step) {
      return new Many(elems, step);
    };

    IndefiniteList.Indefinite = new Indefinite;

    IndefiniteList.Termination = new Termination;

    return IndefiniteList;

  })(OrderedIncrementalList);

  util.extend(module.exports, {
    IndefiniteList: IndefiniteList,
    result: {
      StepResult: StepResult,
      One: One,
      Many: Many,
      Indefinite: Indefinite,
      Termination: Termination
    }
  });

}).call(this);
