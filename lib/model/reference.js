(function() {
  var ModelReference, ModelResolver, Reference, RequestReference, RequestResolver, Resolver, Varying, util, _ref, _ref1,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Varying = require('../core/varying').Varying;

  util = require('../util/util');

  Reference = (function(_super) {
    __extends(Reference, _super);

    Reference.resolverClass = Resolver;

    function Reference(inner, flatValue, options) {
      this.inner = inner;
      this.flatValue = flatValue;
      this.options = options != null ? options : {};
      Reference.__super__.constructor.call(this, {
        value: this._resolver()
      });
    }

    Reference.prototype._resolver = function() {
      return new this.constructor.resolverClass(this, this.inner, this.options);
    };

    Reference.prototype.get = function() {};

    Reference.prototype.watch = function(key) {
      return this.map(function(val) {
        if (val instanceof require('./model').Model) {
          return val.watch(key);
        } else if (val instanceof Resolver) {
          return null;
        } else {
          return val;
        }
      });
    };

    Reference.prototype.watchAll = function() {
      return this.map(function(val) {
        if (val instanceof require('./model').Model) {
          return val.watchAll();
        } else {
          return null;
        }
      });
    };

    return Reference;

  })(Varying);

  Resolver = (function() {
    function Resolver(parent, value, options) {
      this.parent = parent;
      this.value = value;
      this.options = options != null ? options : {};
    }

    Resolver.prototype.resolve = function() {
      return this.parent.setValue(this.value);
    };

    Resolver.prototype.get = function() {};

    Resolver.prototype.watch = function(key) {
      return this.parent.watch(key);
    };

    Resolver.prototype.watchAll = function() {
      return this.parent.watchAll();
    };

    return Resolver;

  })();

  RequestResolver = (function(_super) {
    __extends(RequestResolver, _super);

    function RequestResolver(parent, request, options) {
      var _base, _ref;

      this.parent = parent;
      this.request = request;
      this.options = options != null ? options : {};
      if ((_ref = (_base = this.options).map) == null) {
        _base.map = function(request) {
          return request.map(function(result) {
            return result.successOrElse(null);
          });
        };
      }
    }

    RequestResolver.prototype.resolve = function(app) {
      var store;

      store = app.getStore(this.request);
      if (store != null) {
        store.handle();
        return this.parent.setValue(this.options.map(this.request));
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

  ModelResolver = (function(_super) {
    __extends(ModelResolver, _super);

    function ModelResolver(parent, map, options) {
      this.parent = parent;
      this.map = map;
      this.options = options != null ? options : {};
    }

    ModelResolver.prototype.resolve = function(model) {
      return this.parent.setValue(this.map(model));
    };

    return ModelResolver;

  })(Resolver);

  ModelReference = (function(_super) {
    __extends(ModelReference, _super);

    function ModelReference() {
      _ref1 = ModelReference.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    ModelReference.resolverClass = ModelResolver;

    return ModelReference;

  })(Reference);

  util.extend(module.exports, {
    Reference: Reference,
    RequestReference: RequestReference,
    ModelReference: ModelReference,
    Resolver: Resolver,
    RequestResolver: RequestResolver,
    ModelResolver: ModelResolver
  });

}).call(this);
