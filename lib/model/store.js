(function() {
  var Base, CompleteState, CreateRequest, DeleteRequest, ErrorState, FetchRequest, InitState, MemoryCacheStore, Model, OnPageCacheStore, OneOfStore, PendingState, ProgressState, Request, RequestState, ServiceErrorState, Store, SuccessState, UpdateRequest, UserErrorState, Varying, util, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  Base = require('../core/base').Base;

  Model = require('../model/model').Model;

  Varying = require('../core/varying').Varying;

  RequestState = (function() {
    function RequestState() {}

    RequestState.prototype.flatSuccess = function() {
      return this;
    };

    RequestState.prototype.successOrElse = function(x) {
      if (util.isFunction(x)) {
        return x(this);
      } else {
        return x;
      }
    };

    return RequestState;

  })();

  InitState = (function(_super) {
    __extends(InitState, _super);

    function InitState() {
      _ref = InitState.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    return InitState;

  })(RequestState);

  PendingState = (function(_super) {
    __extends(PendingState, _super);

    function PendingState() {
      _ref1 = PendingState.__super__.constructor.apply(this, arguments);
      return _ref1;
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

    function CompleteState(result) {
      this.result = result;
    }

    CompleteState.prototype.map = function(f) {
      return new CompleteState(f(this.error));
    };

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

    SuccessState.prototype.flatSuccess = function() {
      return this.result;
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

  UserErrorState = (function(_super) {
    __extends(UserErrorState, _super);

    function UserErrorState() {
      _ref2 = UserErrorState.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    return UserErrorState;

  })(ErrorState);

  ServiceErrorState = (function(_super) {
    __extends(ServiceErrorState, _super);

    function ServiceErrorState() {
      _ref3 = ServiceErrorState.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    return ServiceErrorState;

  })(ErrorState);

  Request = (function(_super) {
    __extends(Request, _super);

    function Request(options) {
      this.options = options != null ? options : {};
      Request.__super__.constructor.call(this);
      this.value = Request.state.Init;
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
      Init: new InitState(),
      Pending: new PendingState(),
      Progress: function(progress) {
        return new ProgressState(progress);
      },
      Complete: function(result) {
        return new CompleteState(result);
      },
      Success: function(result) {
        return new SuccessState(result);
      },
      Error: function(error) {
        return new ErrorState(error);
      },
      UserError: function(error) {
        return new UserErrorState(error);
      },
      ServiceError: function(error) {
        return new ServiceErrorState(error);
      },
      type: {
        Init: InitState,
        Pending: PendingState,
        Progress: ProgressState,
        Complete: CompleteState,
        Success: SuccessState,
        Error: ErrorState,
        UserError: UserErrorState,
        ServiceError: ServiceErrorState
      }
    };

    return Request;

  })(Varying);

  Store = (function(_super) {
    __extends(Store, _super);

    function Store(request, options) {
      this.request = request;
      this.options = options != null ? options : {};
      Store.__super__.constructor.call(this);
    }

    Store.prototype.handle = function() {
      var handled;

      handled = this._handle();
      if (handled === Store.Handled) {
        this.emit('requesting', this.request);
        this.request.emit('requesting', this);
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
      _ref4 = FetchRequest.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    return FetchRequest;

  })(Request);

  CreateRequest = (function(_super) {
    __extends(CreateRequest, _super);

    function CreateRequest() {
      _ref5 = CreateRequest.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    return CreateRequest;

  })(Request);

  UpdateRequest = (function(_super) {
    __extends(UpdateRequest, _super);

    function UpdateRequest() {
      _ref6 = UpdateRequest.__super__.constructor.apply(this, arguments);
      return _ref6;
    }

    return UpdateRequest;

  })(Request);

  DeleteRequest = (function(_super) {
    __extends(DeleteRequest, _super);

    function DeleteRequest() {
      _ref7 = DeleteRequest.__super__.constructor.apply(this, arguments);
      return _ref7;
    }

    return DeleteRequest;

  })(Request);

  OneOfStore = (function(_super) {
    __extends(OneOfStore, _super);

    function OneOfStore(request, maybeStores, options) {
      this.request = request;
      this.maybeStores = maybeStores != null ? maybeStores : [];
      this.options = options != null ? options : {};
      OneOfStore.__super__.constructor.call(this, this.request, this.options);
    }

    OneOfStore.prototype._handle = function() {
      var handled, maybeStore, _i, _len, _ref8;

      handled = Store.Unhandled;
      _ref8 = this.maybeStores;
      for (_i = 0, _len = _ref8.length; _i < _len; _i++) {
        maybeStore = _ref8[_i];
        if (handled !== Store.Handled) {
          handled = maybeStore.handle(this.request);
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
      MemoryCacheStore.__super__.constructor.call(this);
    }

    MemoryCacheStore.prototype._cache = function() {
      var _ref8;

      return (_ref8 = this._cache$) != null ? _ref8 : this._cache$ = {};
    };

    MemoryCacheStore.prototype.handle = function(request) {
      var after, hit, signature,
        _this = this;

      signature = request.signature();
      if (signature != null) {
        if (request instanceof FetchRequest) {
          hit = this._cache()[signature];
          if (hit != null) {
            if (hit !== request) {
              request.setValue(hit);
            }
            return Store.Handled;
          } else {
            this._cache()[signature] = request;
            if (request.expires != null) {
              after = util.isFunction(request.expires) ? request.expires() : request.expires;
              if (util.isNumber(after)) {
                setInterval((function() {
                  return delete _this._cache()[signature];
                }), after * 1000);
              }
            }
            return Store.Unhandled;
          }
        } else if ((request instanceof CreateRequest) || (request instanceof UpdateRequest)) {
          delete this._cache()[signature];
          if (request.cacheResult !== false) {
            request.on('changed', function(state) {
              if (state instanceof Request.state.type.Success) {
                return _this._cache()[signature] = state;
              }
            });
          }
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

    function OnPageCacheStore() {
      OnPageCacheStore.__super__.constructor.call(this);
    }

    OnPageCacheStore.prototype._dom = function() {};

    OnPageCacheStore.prototype.handle = function(request) {
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
