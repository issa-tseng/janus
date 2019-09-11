// Generated by CoffeeScript 1.12.2
(function() {
  var Base, ManagedObservation, Varying, nothing, ref, varyingUtils,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  ref = require('janus'), Varying = ref.Varying, Base = ref.Base;

  nothing = {};

  ManagedObservation = (function(superClass) {
    extend(ManagedObservation, superClass);

    function ManagedObservation(varying1) {
      this.varying = varying1;
      ManagedObservation.__super__.constructor.call(this);
    }

    ManagedObservation.prototype.react = function(x, y) {
      return this.reactTo(this.varying, x, y);
    };

    ManagedObservation["with"] = function(varying) {
      return function() {
        return new ManagedObservation(varying);
      };
    };

    return ManagedObservation;

  })(Base);

  varyingUtils = {
    ManagedObservation: ManagedObservation,
    sticky: function(delays, v) {
      if (delays == null) {
        delays = {};
      }
      if (v == null) {
        return (function(v) {
          return varyingUtils.sticky(delays, v);
        });
      }
      return Varying.managed(ManagedObservation["with"](v), function(mo) {
        var result, timer, update, value;
        result = new Varying(v.get());
        value = timer = null;
        update = function() {
          timer = null;
          return result.set(value);
        };
        mo.react(function(newValue) {
          var delay;
          if (timer != null) {
            return value = newValue;
          } else if ((delay = delays[value]) != null) {
            value = newValue;
            return timer = setTimeout(update, delay);
          } else {
            value = newValue;
            return update();
          }
        });
        return result;
      });
    },
    debounce: function(cooldown, v) {
      if (v == null) {
        return (function(v) {
          return varyingUtils.debounce(cooldown, v);
        });
      }
      return Varying.managed(ManagedObservation["with"](v), function(mo) {
        var result, timer;
        result = new Varying(v.get());
        timer = null;
        mo.react(function(value) {
          if (timer != null) {
            clearTimeout(timer);
          }
          return timer = setTimeout((function() {
            return result.set(value);
          }), cooldown);
        });
        return result;
      });
    },
    throttle: function(delay, v) {
      if (v == null) {
        return (function(v) {
          return varyingUtils.throttle(delay, v);
        });
      }
      return Varying.managed(ManagedObservation["with"](v), function(mo) {
        var pendingValue, result, timer;
        result = new Varying(v.get());
        timer = null;
        pendingValue = nothing;
        mo.react(false, function(value) {
          if (timer != null) {
            return pendingValue = value;
          } else {
            result.set(value);
            return timer = setTimeout((function() {
              timer = null;
              if (pendingValue === nothing) {
                return;
              }
              result.set(pendingValue);
              return pendingValue = nothing;
            }), delay);
          }
        });
        return result;
      });
    },
    filter: function(predicate, v) {
      if (v == null) {
        return (function(v) {
          return varyingUtils.filter(predicate, v);
        });
      }
      return Varying.managed(ManagedObservation["with"](v), function(mo) {
        var lastObservation, result;
        result = new Varying(void 0);
        lastObservation = null;
        mo.react(function(value) {
          if (lastObservation != null) {
            lastObservation.stop();
          }
          return lastObservation = Varying.of(predicate(value)).react(function(take) {
            if (take === true) {
              return result.set(value);
            }
          });
        });
        return result;
      });
    },
    zipSequential: function(v) {
      return Varying.managed(ManagedObservation["with"](v), function(mo) {
        var last, result;
        result = new Varying([]);
        last = nothing;
        mo.react(function(value) {
          if (last !== nothing) {
            result.set([last, value]);
          }
          return last = value;
        });
        return result;
      });
    },
    fromEvent: function(jq, event, x, y) {
      var f, initial, manager;
      initial = y === void 0 ? true : x;
      f = y != null ? y : x;
      manager = function(d_) {
        return manager.destroy = d_;
      };
      return Varying.managed((function() {
        return manager;
      }), function(destroyer) {
        var f_, result;
        result = new Varying();
        f_ = function(event) {
          return result.set(f.call(this, event));
        };
        if (initial === true) {
          f_();
        }
        jq.on(event, f_);
        destroyer(function() {
          return jq.off(event, f_);
        });
        return result;
      });
    },
    fromEvents: function(jq, initial, eventMap) {
      var manager;
      manager = function(d_) {
        return manager.destroy = d_;
      };
      return Varying.managed((function() {
        return manager;
      }), function(destroyer) {
        var handler, k, result;
        result = new Varying(initial);
        handler = function(event) {
          return result.set(eventMap[event.type]);
        };
        for (k in eventMap) {
          jq.on(k, handler);
        }
        destroyer(function() {
          for (k in eventMap) {
            jq.off(k, handler);
          }
        });
        return result;
      });
    }
  };

  module.exports = varyingUtils;

}).call(this);