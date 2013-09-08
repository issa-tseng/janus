(function() {
  var Base, Endpoint, Handler, HttpHandler, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  util = require('../util/util');

  Base = require('../core/base').Base;

  Endpoint = require('./endpoint').Endpoint;

  Handler = (function(_super) {
    __extends(Handler, _super);

    function Handler() {
      Handler.__super__.constructor.call(this);
    }

    Handler.prototype.handler = function() {
      return function() {};
    };

    return Handler;

  })(Base);

  HttpHandler = (function(_super) {
    __extends(HttpHandler, _super);

    function HttpHandler(endpoint) {
      this.endpoint = endpoint;
      HttpHandler.__super__.constructor.call(this);
    }

    HttpHandler.prototype.handle = function(request, response, params) {
      return this.endpoint.handle({
        url: request.url,
        params: params,
        headers: request.headers,
        requestStream: request.request,
        responseStream: response.response
      }, function(result) {
        response.writeHead(result.httpCode, {
          'Content-Type': 'text/html'
        });
        response.write(result.content);
        return response.end();
      });
    };

    HttpHandler.prototype.handler = function() {
      var self;
      self = this;
      return function() {
        var params;
        params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return self.handle(this.req, this.res, params);
      };
    };

    return HttpHandler;

  })(Handler);

  util.extend(module.exports, {
    Handler: Handler,
    HttpHandler: HttpHandler
  });

}).call(this);
