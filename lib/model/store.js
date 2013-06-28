(function() {
  var Base, CompleteState, CreateRequest, DeleteRequest, ErrorState, FetchRequest, MemoryCacheStore, Model, OnPageCacheStore, OneOfStore, PendingState, ProgressState, Request, RequestState, Store, SuccessState, UpdateRequest, Varying, util, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  Base = require('../core/base').Base;

  Model = require('../model/model').Model;

  Varying = require('../core/varying').Varying;

  RequestState = (function() {
    function RequestState() {}

    RequestState.prototype.successOrElse = function(x) {
      if (util.isFunction(x)) {
        return x(this);
      } else {
        return x;
      }
    };

    return RequestState;

  })();

  PendingState = (function(_super) {
    __extends(PendingState, _super);

    function PendingState() {
      _ref = PendingState.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    return PendingState;

  })(RequestState);

  ProgressState = (function(_super) {
    __extends(ProgressState, _super);

    function ProgressState(progress) {
      this.progress = progress;
    }

    ProgressState.prototype.map = function(f) {
      return new ProgressState(f(this.progress));
    };

    return ProgressState;

  })(PendingState);

  CompleteState = (function(_super) {
    __extends(CompleteState, _super);

    function CompleteState() {
      _ref1 = CompleteState.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    return CompleteState;

  })(RequestState);

  SuccessState = (function(_super) {
    __extends(SuccessState, _super);

    function SuccessState(result) {
      this.result = result;
    }

    SuccessState.prototype.map = function(f) {
      return new SuccessState(f(this.result));
    };

    SuccessState.prototype.successOrElse = function() {
      return this.result;
    };

    return SuccessState;

  })(CompleteState);

  ErrorState = (function(_super) {
    __extends(ErrorState, _super);

    function ErrorState(error) {
      this.error = error;
    }

    ErrorState.prototype.map = function(f) {
      return new ErrorState(f(this.error));
    };

    return ErrorState;

  })(CompleteState);

  Request = (function(_super) {
    __extends(Request, _super);

    function Request() {
      Request.__super__.constructor.call(this);
      this.value = Request.state.Pending;
    }

    Request.prototype.signature = function() {};

    Request.prototype.setValue = function(response) {
      return Request.__super__.setValue.call(this, this.deserialize(response));
    };

    Request.prototype.deserialize = function(response) {
      var _this = this;

      if (response instanceof Request.state.type.Success) {
        return response.map(function(data) {
          return _this.constructor.modelClass.deserialize(data);
        });
      } else {
        return response;
      }
    };

    Request.modelClass = Model;

    Request.state = {
      Pending: new PendingState(),
      Progress: function(progress) {
        return new ProgressState(progress);
      },
      Complete: new CompleteState(),
      Success: function(result) {
        return new SuccessState(result);
      },
      Error: function(error) {
        return new ErrorState(error);
      },
      type: {
        Pending: PendingState,
        Progress: ProgressState,
        Complete: CompleteState,
        Success: SuccessState,
        Error: ErrorState
      }
    };

    return Request;

  })(Varying);

  Store = (function(_super) {
    __extends(Store, _super);

    function Store(request) {
      this.request = request;
      Store.__super__.constructor.call(this);
    }

    Store.prototype.handle = function() {
      var handled;

      handled = this._handle();
      if (handled === Store.Handled) {
        this.emit('requesting', this.request);
      }
      return handled;
    };

    Store.Handled = {};

    Store.Unhandled = {};

    return Store;

  })(Base);

  FetchRequest = (function(_super) {
    __extends(FetchRequest, _super);

    function FetchRequest() {
      _ref2 = FetchRequest.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    return FetchRequest;

  })(Request);

  CreateRequest = (function(_super) {
    __extends(CreateRequest, _super);

    function CreateRequest() {
      _ref3 = CreateRequest.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    return CreateRequest;

  })(Request);

  UpdateRequest = (function(_super) {
    __extends(UpdateRequest, _super);

    function UpdateRequest() {
      _ref4 = UpdateRequest.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    return UpdateRequest;

  })(Request);

  DeleteRequest = (function(_super) {
    __extends(DeleteRequest, _super);

    function DeleteRequest() {
      _ref5 = DeleteRequest.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    return DeleteRequest;

  })(Request);

  OneOfStore = (function(_super) {
    __extends(OneOfStore, _super);

    function OneOfStore() {
      _ref6 = OneOfStore.__super__.constructor.apply(this, arguments);
      return _ref6;
    }

    OneOfStore.handlers = [];

    OneOfStore.prototype._handler = function(request) {
      var handled, handler, _i, _len, _ref7;

      handled = Store.Unhandled;
      _ref7 = this.constructor.handlers;
      for (_i = 0, _len = _ref7.length; _i < _len; _i++) {
        handler = _ref7[_i];
        if (handled !== Store.Handled) {
          handled = handler(request);
        }
      }
      if (handled === Store.Unhandled) {
        request.setValue(Request.state.Error("No handler was available!"));
      }
      return handled;
    };

    return OneOfStore;

  })(Store);

  MemoryCacheStore = (function(_super) {
    __extends(MemoryCacheStore, _super);

    function MemoryCacheStore() {
      _ref7 = MemoryCacheStore.__super__.constructor.apply(this, arguments);
      return _ref7;
    }

    MemoryCacheStore.prototype._cache = function() {
      return {};
    };

    MemoryCacheStore.prototype._handle = function(request) {
      var signature,
        _this = this;

      signature = request.signature();
      if (signature != null) {
        if (request instanceof FetchRequest) {
          if (this._cache()[signature] != null) {
            request.setValue(Request.state.Success(this._cache()[signature]));
            return Store.Handled;
          } else {
            request.on('changed', function(state) {
              if (state instanceof Request.state.type.Success) {
                return _this._cache()[signature] = state.result;
              }
            });
            return Store.Unhandled;
          }
        } else if ((request instanceof CreateRequest) || (request instanceof UpdateRequest)) {
          delete this._cache()[signature];
          request.on('changed', function(state) {
            if (state instanceof Request.state.type.Success) {
              return _this._cache()[signature] = state.result;
            }
          });
          return Store.Unhandled;
        } else {
          delete this._cache()[signature];
          return Store.Unhandled;
        }
      } else {
        return Store.Unhandled;
      }
    };

    return MemoryCacheStore;

  })(Store);

  OnPageCacheStore = (function(_super) {
    __extends(OnPageCacheStore, _super);

    function OnPageCacheStore(request) {
      this.request = request;
      OnPageCacheStore.__super__.constructor.call(this);
    }

    OnPageCacheStore.prototype._dom = function() {};

    OnPageCacheStore.prototype._handle = function(request) {
      var cacheDom, signature;

      signature = request.signature();
      if (signature != null) {
        cacheDom = this._dom().find("> #" + signature);
        if (cacheDom.length > 0) {
          if (request instanceof FetchRequest) {
            request.setValue(Request.state.Success(cacheDom.text()));
            return Store.Handled;
          } else {
            cacheDom.remove();
            return Store.Unhandled;
          }
        } else {
          return Store.Unhandled;
        }
      } else {
        return Store.Unhandled;
      }
    };

    return OnPageCacheStore;

  })(Store);

  util.extend(module.exports, {
    Request: Request,
    Store: Store,
    OneOfStore: OneOfStore,
    MemoryCacheStore: MemoryCacheStore,
    OnPageCacheStore: OnPageCacheStore,
    request: {
      FetchRequest: FetchRequest,
      CreateRequest: CreateRequest,
      UpdateRequest: UpdateRequest,
      DeleteRequest: DeleteRequest
    }
  });

}).call(this);
