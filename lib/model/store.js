(function() {
  var Base, Complete, Error, Model, OneOfStore, Pending, Progress, Request, RequestStatus, Store, Success, Varying, util, _ref, _ref1,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  Base = require('../core/base').Base;

  Model = require('../model/model').Model;

  Varying = require('../core/varying').Varying;

  Store = (function(_super) {
    __extends(Store, _super);

    function Store(handler) {
      this.handler = handler;
    }

    Store.prototype.handle = function(request) {
      this.emit('requesting', request);
      this.handler(request);
      return request;
    };

    return Store;

  })(Base);

  OneOfStore = (function(_super) {
    __extends(OneOfStore, _super);

    function OneOfStore(handlers) {
      this.handlers = handlers;
      this.handler = function(request) {
        var handled, handler, _i, _len, _ref;

        handled = OneOfStore.Unhandled;
        _ref = this.handlers;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          handler = _ref[_i];
          if (handled !== OneOfStore.Handled) {
            handled = handler(request);
          }
        }
        if (handled === OneOfStore.Unhandled) {
          return request.setValue(Request.status.Error("No handler was available!"));
        }
      };
    }

    OneOfStore.Handled = {};

    OneOfStore.Unhandled = {};

    return OneOfStore;

  })(Store);

  RequestStatus = (function() {
    function RequestStatus() {}

    return RequestStatus;

  })();

  Pending = (function(_super) {
    __extends(Pending, _super);

    function Pending() {
      _ref = Pending.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    return Pending;

  })(RequestStatus);

  Progress = (function(_super) {
    __extends(Progress, _super);

    function Progress(progress) {
      this.progress = progress;
    }

    return Progress;

  })(Pending);

  Complete = (function(_super) {
    __extends(Complete, _super);

    function Complete() {
      _ref1 = Complete.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    return Complete;

  })(RequestStatus);

  Success = (function(_super) {
    __extends(Success, _super);

    function Success(result) {
      this.result = result;
    }

    return Success;

  })(Complete);

  Error = (function(_super) {
    __extends(Error, _super);

    function Error(error) {
      this.error = error;
    }

    return Error;

  })(Complete);

  Request = (function(_super) {
    __extends(Request, _super);

    function Request() {
      Request.__super__.constructor.call(this);
      this.value = Request.status.Pending;
    }

    Request.status = {
      Pending: new Pending(),
      Progress: function(progress) {
        return new Progress(progress);
      },
      Complete: new Complete(),
      Success: function(result) {
        return new Success(result);
      },
      Error: function(error) {
        return new Error(error);
      }
    };

    return Request;

  })(Varying);

  util.extend(module.exports, {
    Store: Store,
    Request: Request
  });

}).call(this);
