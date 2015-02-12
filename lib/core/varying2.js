(function() {
  var Base, MappedVarying, Reaction, Reactor, Varying, util,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  Base = require('../core/base').Base;

  util = require('../util/util');

  Reaction = (function() {
    function Reaction(fs, _arg) {
      this.fs = fs;
      this.late = _arg.late, this.preceding = _arg.preceding;
      this.dependents = [];
      this.chainCount = 0;
      this.id = util.uniqueId();
    }

    Reaction.prototype.sortClass = function() {
      if (this.late === null) {
        return 0;
      } else {
        return 1;
      }
    };

    Reaction.prototype.length = function() {
      var _ref, _ref1;

      return ((_ref = (_ref1 = this.preceding) != null ? _ref1.length() : void 0) != null ? _ref : 0) + this.fs.length;
    };

    Reaction.prototype.endsWith = function(f) {
      return util.last(this.fs) === f;
    };

    Reaction.prototype.longestMatch = function(otherfs) {
      var d, f, idx, match, remainder, _i, _j, _len, _len1, _ref, _ref1;

      if (otherfs[0] !== this.fs[0]) {
        return false;
      }
      remainder = otherfs.slice();
      _ref = this.fs;
      for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
        f = _ref[idx];
        if (f !== otherfs[0]) {
          return [this, this.fs.slice(0, idx), remainder];
        }
        otherfs.shift();
      }
      _ref1 = this.dependents;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        d = _ref1[_j];
        if (match = d.longestMatch(remainder) !== false) {
          return match;
        }
      }
      return [this, this.fs, remainder];
    };

    Reaction.prototype.split = function(idx) {
      var dependent, head, tail, _i, _len, _ref;

      head = new Reaction(this.fs.slice(0, idx), {
        preceding: this.preceding
      });
      tail = new Reaction(this.fs.slice(idx), {
        preceding: head,
        dependents: this.dependents
      });
      head.dependents = [tail];
      if (this.preceding != null) {
        util.resplice(this.preceding.dependents, this, head);
      }
      _ref = this.dependents;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        dependent = _ref[_i];
        dependent.preceding = tail;
      }
      return [head, tail];
    };

    Reaction.prototype.execute = function(input) {
      var f, result, _i, _len, _ref;

      result = input;
      _ref = this.fs;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        f = _ref[_i];
        result = f(result);
      }
      return result;
    };

    return Reaction;

  })();

  Reactor = (function() {
    function Reactor() {
      this.roots = [];
      this.leaves = [];
      this.cache = {};
    }

    Reactor.prototype.add = function(fs, late) {
      var divergent, head, leaf, match, reaction, remainder, root, shared, tail, _i, _len, _ref, _ref1;

      reaction = new Reaction(fs, {
        late: late
      });
      match = false;
      _ref = this.roots;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        root = _ref[_i];
        if ((match = root.longestMatch(fs)) !== false) {
          break;
        }
      }
      if (match === false) {
        this.roots.push(reaction);
        this.leaves.push(reaction);
      } else {
        divergent = match[0], shared = match[1], remainder = match[2];
        leaf = new Reaction(remainder, {
          preceding: divergent,
          late: reaction.late
        });
        this.leaves.push(leaf);
        if (shared.length === divergent.length) {
          if (remainder.length === 0) {
            return;
          }
          divergent.dependents.push(leaf);
        } else {
          _ref1 = divergent.split(shared.length), head = _ref1[0], tail = _ref1[1];
          tail.dependents.push(leaf);
          if (__indexOf.call(this.roots, divergent) >= 0) {
            util.resplice(this.roots, divergent, head);
          }
          if (__indexOf.call(this.leaves, divergent) >= 0) {
            util.resplice(this.leaves, divergent, tail);
          }
        }
      }
      this.sort();
      return leaf;
    };

    Reactor.prototype.remove = function(f) {
      var target;

      target = this.findLeaf(f);
      if (target === null || target.dependents.length !== 0) {
        return false;
      }
      this.leaves.splice(this.leaves.indexOf(target), 1);
      return true;
    };

    Reactor.prototype.findLeaf = function(f) {
      var leaf, target, _i, _len, _ref;

      target = null;
      _ref = this.leaves;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        leaf = _ref[_i];
        if (leaf.endsWith(f)) {
          target = leaf;
          break;
        }
      }
      return target;
    };

    Reactor.prototype.executeLeaf = function(leaf) {
      var cur, toExecute, _ref;

      toExecute = [leaf];
      while (toExecute.length !== 0) {
        cur = toExecute.pop();
        if (cur.preceding === null) {
          this.cache[cur.id] = cur.execute(value);
        } else if (_ref = cur.preceding._id, __indexOf.call(this.cache, _ref) >= 0) {
          this.cache[cur.id] = cur.execute(this.cache[cur.preceding._id]);
        } else {
          toExecute.push(cur);
          toExecute.push(cur.preceding);
        }
      }
      return null;
    };

    Reactor.prototype.executeFunc = function(f) {
      var leaf;

      leaf = this.findLeaf(f);
      if (leaf != null) {
        return this.executeLeaf(leaf);
      }
    };

    Reactor.prototype.react = function(value, id) {
      var firstReaction, lastReaction, lateLeaves, leaf, needsSort, _i, _j, _len, _len1, _ref;

      firstReaction = this.isReacting !== true;
      this.isReacting = true;
      needsSort = false;
      this.cache = {};
      this.completedReacting = false;
      lateLeaves = (function() {
        var _i, _len, _ref, _results;

        if (firstReaction === true) {
          _ref = this.leaves;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            leaf = _ref[_i];
            if (!(leaf.late !== null)) {
              continue;
            }
            leaf.late.claimant = id;
            _results.push(leaf);
          }
          return _results;
        } else {
          return [];
        }
      }).call(this);
      _ref = this.leaves;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        leaf = _ref[_i];
        if (!(leaf.late === null)) {
          continue;
        }
        if (this.completedReacting = true) {
          break;
        }
        lastReaction = this.lastReaction;
        this.executeLeaf(leaf);
        if (lastReaction !== this.lastReaction) {
          leaf.chainCount += 1;
          needsSort = true;
        }
      }
      for (_j = 0, _len1 = lateLeaves.length; _j < _len1; _j++) {
        leaf = lateLeaves[_j];
        this.executeLeaf(leaf);
        if (leaf.late.claimant = id) {
          leaf.late.execute();
          leaf.late.claimant = null;
        }
      }
      if (needsSort === true) {
        this.sort();
      }
      this.lastReaction = id;
      if (firstReaction === true) {
        this.completedReacting = false;
        this.isReacting = false;
      } else {
        this.completedReacting = true;
      }
      return null;
    };

    Reactor.prototype.sort = function() {
      return this.leaves.sort(function(a, b) {
        var _ref, _ref1;

        return (_ref = (_ref1 = b.chainCount() - a.chainCount()) != null ? _ref1 : a.sortClass() - b.sortClass()) != null ? _ref : 0;
      });
    };

    return Reactor;

  })();

  Varying = (function(_super) {
    __extends(Varying, _super);

    function Varying(value) {
      Varying.__super__.constructor.call(this);
      this.reactor = new Reactor();
      this.setValue(value);
    }

    Varying.prototype.react = function() {
      var fs;

      fs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.reactor.add(fs);
    };

    Varying.prototype.reactLate = function() {
      var fs, late;

      late = arguments[0], fs = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return this.reactor.add(fs, late);
    };

    Varying.prototype.reactNow = function() {
      var fs;

      fs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this.reactor.add(fs);
      return this.reactor.executeFunc(util.last(fs));
    };

    Varying.prototype.reactLateNow = function() {
      var fs, late;

      late = arguments[0], fs = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      this.reactor.add(fs, late);
      return this.reactor.executeFunc(util.last(fs));
    };

    Varying.prototype.setValue = function(value) {
      if (this._value === value) {
        return;
      }
      this._value = value;
      return this.reactor.react(value, util.uniqueId());
    };

    Varying.prototype.map = function(f) {
      return new MappedVarying(this, f);
    };

    Varying.prototype.flatten = function() {
      return this;
    };

    Varying.prototype.and = function(varying) {
      return new MultiVarying(this, varying);
    };

    Varying.prototype.getValue = function() {
      return this._value;
    };

    return Varying;

  })(Base);

  MappedVarying = (function() {
    function MappedVarying(from, map) {
      this.from = from;
      this.map = map;
    }

    MappedVarying.prototype.react = function() {
      var fs, _ref;

      fs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return (_ref = this.from).react.apply(_ref, [this.map].concat(__slice.call(fs)));
    };

    MappedVarying.prototype.reactLate = function() {
      var fs, late, _ref;

      late = arguments[0], fs = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return (_ref = this.from).reactLate.apply(_ref, [late, this.map].concat(__slice.call(fs)));
    };

    MappedVarying.prototype.reactNow = function() {
      var fs, _ref;

      fs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return (_ref = this.from).reactNow.apply(_ref, [this.map].concat(__slice.call(fs)));
    };

    MappedVarying.prototype.reactLateNow = function() {
      var fs, late, _ref;

      late = arguments[0], fs = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return (_ref = this.from).reactLateNow.apply(_ref, [late, this.map].concat(__slice.call(fs)));
    };

    MappedVarying.prototype.map = function(f) {
      return new MappedVarying(this, f);
    };

    MappedVarying.prototype.and = function(varying) {
      return new MultiVarying(this, varying);
    };

    MappedVarying.prototype.getValue = function() {
      throw new Error('Trying to getValue() from a mapped varying! This is not something you can do.');
    };

    return MappedVarying;

  })();

}).call(this);
