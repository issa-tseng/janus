(function() {
  var App, Base, Endpoint, EndpointResponse, ForbiddenResponse, InternalErrorResponse, InvalidRequestResponse, NotFoundResponse, OkResponse, Request, StoreManifest, UnauthorizedResponse, util, _ref, _ref1, _ref2, _ref3, _ref4, _ref5,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  Base = require('../core/base').Base;

  Request = require('../model/store').Request;

  App = require('./app').App;

  StoreManifest = require('./manifest').StoreManifest;

  EndpointResponse = (function() {
    function EndpointResponse(content) {
      this.content = content;
    }

    return EndpointResponse;

  })();

  OkResponse = (function(_super) {
    __extends(OkResponse, _super);

    function OkResponse() {
      _ref = OkResponse.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    OkResponse.prototype.httpCode = 200;

    return OkResponse;

  })(EndpointResponse);

  InvalidRequestResponse = (function(_super) {
    __extends(InvalidRequestResponse, _super);

    function InvalidRequestResponse() {
      _ref1 = InvalidRequestResponse.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    InvalidRequestResponse.prototype.httpCode = 400;

    return InvalidRequestResponse;

  })(EndpointResponse);

  UnauthorizedResponse = (function(_super) {
    __extends(UnauthorizedResponse, _super);

    function UnauthorizedResponse() {
      _ref2 = UnauthorizedResponse.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    UnauthorizedResponse.prototype.httpCode = 401;

    return UnauthorizedResponse;

  })(EndpointResponse);

  ForbiddenResponse = (function(_super) {
    __extends(ForbiddenResponse, _super);

    function ForbiddenResponse() {
      _ref3 = ForbiddenResponse.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    ForbiddenResponse.prototype.httpCode = 403;

    return ForbiddenResponse;

  })(EndpointResponse);

  NotFoundResponse = (function(_super) {
    __extends(NotFoundResponse, _super);

    function NotFoundResponse() {
      _ref4 = NotFoundResponse.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    NotFoundResponse.prototype.httpCode = 404;

    return NotFoundResponse;

  })(EndpointResponse);

  InternalErrorResponse = (function(_super) {
    __extends(InternalErrorResponse, _super);

    function InternalErrorResponse() {
      _ref5 = InternalErrorResponse.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    InternalErrorResponse.prototype.httpCode = 500;

    return InternalErrorResponse;

  })(EndpointResponse);

  Endpoint = (function(_super) {
    __extends(Endpoint, _super);

    function Endpoint(pageModelClass, pageLibrary, app) {
      this.pageModelClass = pageModelClass;
      this.pageLibrary = pageLibrary;
      this.app = app;
      Endpoint.__super__.constructor.call(this);
    }

    Endpoint.prototype.handle = function(env, respond) {
      var app, dom, manifest, pageModel, pageView,
        _this = this;

      app = this.initApp(env);
      manifest = new StoreManifest(app.get('stores'));
      manifest.on('allComplete', function() {
        return _this.finish(pageModel, pageView, manifest, respond);
      });
      manifest.on('requestComplete', function(request) {
        if (request.value instanceof Request.state.type.Error && request.options.fatal === true) {
          return _this.error(request, respond);
        }
      });
      pageModel = new this.pageModelClass({
        env: env
      }, {
        app: app
      });
      pageView = this.pageLibrary.get(pageModel, {
        context: env.context,
        constructorOpts: {
          app: app
        }
      });
      dom = this.initPageView(pageView, env);
      pageModel.resolve();
      return dom;
    };

    Endpoint.prototype.initApp = function(env) {
      var storeLibrary;

      storeLibrary = this.app.get('stores').newEventBindings();
      return this.app.withStoreLibrary(storeLibrary);
    };

    Endpoint.prototype.initPageView = function(pageView, env) {
      return pageView.artifact();
    };

    Endpoint.prototype.finish = function(pageModel, pageView, manifest, respond) {
      return respond(new OkResponse(pageView.markup()));
    };

    Endpoint.prototype.error = function(request, respond) {
      return respond(new InternalErrorResponse());
    };

    Endpoint.factoryWith = function(pageLibrary, app) {
      var self;

      self = this;
      return function(pageModelClass) {
        return new self(pageModelClass, pageLibrary, app);
      };
    };

    return Endpoint;

  })(Base);

  util.extend(module.exports, {
    Endpoint: Endpoint,
    responses: {
      EndpointResponse: EndpointResponse,
      OkResponse: OkResponse,
      InvalidRequestResponse: InvalidRequestResponse,
      UnauthorizedResponse: UnauthorizedResponse,
      ForbiddenResponse: ForbiddenResponse,
      NotFoundResponse: NotFoundResponse,
      InternalErrorResponse: InternalErrorResponse
    }
  });

}).call(this);
