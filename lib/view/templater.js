(function() {
  var BoundTemplate, Mutation, Template, build, find, mutators, template,
    __slice = [].slice;

  mutators = require('./mutators');

  Mutation = (function() {
    Mutation.prototype.isMutation = true;

    function Mutation(selector, mutator) {
      this.selector = selector;
      this.mutator = mutator;
    }

    return Mutation;

  })();

  build = function(objs) {
    var klass, methods, name, obj, _fn, _i, _len;

    methods = {};
    for (_i = 0, _len = objs.length; _i < _len; _i++) {
      obj = objs[_i];
      _fn = function(name, kase) {
        return methods[name] = function(selector) {
          return function() {
            var args;

            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return new Mutation(selector, (function(func, args, ctor) {
              ctor.prototype = func.prototype;
              var child = new ctor, result = func.apply(child, args);
              return Object(result) === result ? result : child;
            })(klass, args, function(){}));
          };
        };
      };
      for (name in obj) {
        klass = obj[name];
        _fn(name, kase);
      }
    }
    return function(selector) {
      var k, result, v;

      result = {
        selector: selector
      };
      for (k in methods) {
        v = methods[k];
        result[k] = v(selector);
      }
      return result;
    };
  };

  find = build(mutators);

  find.build = build;

  Template = (function() {
    Template.prototype.isTemplate = true;

    function Template(mutations) {
      this.mutations = mutations;
    }

    Template.prototype.bind = function(dom, point) {
      return new BoundTemplate(dom, this.mutations, point);
    };

    return Template;

  })();

  template = function() {
    var mutation, mutations, result, _i, _len;

    mutations = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    result = [];
    for (_i = 0, _len = mutations.length; _i < _len; _i++) {
      mutation = mutations[_i];
      if (mutation.isMutation === true) {
        result.push(mutation);
      } else {
        result = result.concat(template(mutation));
      }
    }
    return new Template(result);
  };

  BoundTemplate = (function() {
    function BoundTemplate(dom, mutations, point) {
      var wrapper;

      this.dom = dom;
      this.mutations = mutations;
      dom.prepend('<div/>');
      this.wrappedDom = wrapper = dom.children(':first');
      wrapper.remove();
      wrapper.append(dom);
      this.point(point);
      this._bind(point);
    }

    BoundTemplate.prototype._bind = function(point) {
      var mutation, _i, _len, _ref;

      _ref = this.mutations;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        mutation = _ref[_i];
        mutation.mutator.bind(this.wrappedDom.find(mutation.selector));
      }
      return null;
    };

    BoundTemplate.prototype.point = function(point) {
      var mutation, _i, _len, _ref;

      _ref = this.mutations;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        mutation = _ref[_i];
        mutation.mutator.point(point);
      }
      return null;
    };

    BoundTemplate.prototype.destroy = function() {
      var mutation, _i, _len, _ref;

      _ref = this.mutations;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        mutation = _ref[_i];
        mutation.mutator.stop();
      }
      dom.trigger('destroying');
      return null;
    };

    return BoundTemplate;

  })();

  module.exports = {
    template: template,
    find: find
  };

}).call(this);
