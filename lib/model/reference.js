(function() {
  var Reference, RequestReference, RequestResolver, Resolver, Varying, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Varying = require('../core/varying').Varying;

  util = require('../util/util');

  Resolver = (function() {
    function Resolver(parent, value) {
      this.parent = parent;
      this.value = value;
    }

    Resolver.prototype.resolve = function() {
      return this.parent.setValue(this.value);
    };

    return Resolver;

  })();

  Reference = (function(_super) {
    __extends(Reference, _super);

    Reference.resolverClass = Resolver;

    function Reference(value) {
      var resolver;

      resolver = new this.constructor.resolverClass(this, value);
      Reference.__super__.constructor.call(this, {
        value: resolver
      });
    }

    return Reference;

  })(Varying);

  RequestResolver = (function(_super) {
    __extends(RequestResolver, _super);

    function RequestResolver(parent, request) {
      this.parent = parent;
      this.request = request;
    }

    RequestResolver.prototype.resolve = function(app) {
      var store;

      store = app.getStore(this.request);
      if (store != null) {
        store.handle();
        return this.parent.setValue(this.request.map(function(result) {
          return result.successOrElse(null);
        }));
      } else {
        return this.parent.setValue(null);
      }
    };

    return RequestResolver;

  })(Resolver);

  RequestReference = (function(_super) {
    __extends(RequestReference, _super);

    function RequestReference() {
      _ref = RequestReference.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    RequestReference.resolverClass = RequestResolver;

    return RequestReference;

  })(Reference);

  util.extend(module.exports, {
    Resolver: Resolver,
    Reference: Reference,
    RequestResolver: RequestResolver,
    RequestReference: RequestReference
  });

}).call(this);
