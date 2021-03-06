// Generated by CoffeeScript 1.12.2
(function() {
  var List, Varying, closest, closest_, identity, into, intoAll, intoAll_, into_, isFunction, isNumber, isString, match, parent, parent_, ref, rewriteSelector;

  ref = require('../util/util'), isString = ref.isString, isNumber = ref.isNumber, isFunction = ref.isFunction, identity = ref.identity;

  Varying = require('../core/varying').Varying;

  List = require('../collection/list').List;

  rewriteSelector = function(selector, view) {
    var base, target;
    if ((isString(selector) || isNumber(selector)) && (view.subject != null)) {
      if ((target = typeof (base = view.subject).get_ === "function" ? base.get_(selector) : void 0) != null) {
        return target;
      }
    }
    return selector;
  };

  match = function(selector, view) {
    if (void 0 === selector) {
      return true;
    } else if (view === selector) {
      return true;
    } else if ((view != null ? view.subject : void 0) === selector) {
      return true;
    } else if (selector[Symbol.hasInstance] != null) {
      if (view instanceof selector) {
        return true;
      } else if ((view != null ? view.subject : void 0) instanceof selector) {
        return true;
      }
    }
  };

  parent_ = function(selector, view) {
    var candidate;
    candidate = view.options.parent;
    if (candidate && match(selector, candidate)) {
      return candidate;
    }
  };

  closest_ = function(selector, view) {
    var candidate;
    candidate = view;
    while ((candidate = candidate.options.parent) != null) {
      if (match(selector, candidate)) {
        return candidate;
      }
    }
  };

  parent = function(selector, view) {
    return new Varying(parent_(selector, view));
  };

  closest = function(selector, view) {
    return new Varying(closest_(selector, view));
  };

  into_ = function(selector, view) {
    var candidate, i, len, ref1;
    selector = rewriteSelector(selector, view);
    ref1 = view.subviews_();
    for (i = 0, len = ref1.length; i < len; i++) {
      candidate = ref1[i];
      if (match(selector, candidate)) {
        return candidate;
      }
    }
  };

  intoAll_ = function(selector, view) {
    var candidate, i, len, ref1, results;
    selector = rewriteSelector(selector, view);
    ref1 = view.subviews_();
    results = [];
    for (i = 0, len = ref1.length; i < len; i++) {
      candidate = ref1[i];
      if (match(selector, candidate)) {
        results.push(candidate);
      }
    }
    return results;
  };

  into = function(selector, view) {
    return intoAll(selector, view).get(0);
  };

  intoAll = function(selector, view) {
    selector = Varying.of(selector).flatMap(function(sel) {
      var ref1;
      if (isNumber(sel) || isString(sel) && isFunction((ref1 = view.subject) != null ? ref1.get : void 0)) {
        return view.subject.get(sel);
      } else {
        return sel;
      }
    });
    return view.subviews().filter(function(view) {
      return selector.map(function(s) {
        return match(s, view);
      });
    });
  };

  module.exports = {
    match: match,
    parent_: parent_,
    closest_: closest_,
    into_: into_,
    intoAll_: intoAll_,
    parent: parent,
    closest: closest,
    into: into,
    intoAll: intoAll
  };

}).call(this);
