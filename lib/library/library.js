(function() {
  var Base, Library, match, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require('../util/util');

  Base = require('../core/base').Base;

  Library = (function(_super) {
    __extends(Library, _super);

    Library.prototype._defaultContext = 'default';

    function Library(options) {
      var _base, _ref;

      this.options = options != null ? options : {};
      Library.__super__.constructor.call(this);
      this.bookcase = {};
      if ((_ref = (_base = this.options).handler) == null) {
        _base.handler = function(obj, book, options) {
          return new book(obj, options.constructorOpts);
        };
      }
    }

    Library.prototype.register = function(klass, book, options) {
      var bookId, classShelf, contextShelf, _base, _name, _ref, _ref1, _ref2;

      if (options == null) {
        options = {};
      }
      bookId = Library._classId(klass);
      classShelf = (_ref = (_base = this.bookcase)[bookId]) != null ? _ref : _base[bookId] = {};
      contextShelf = (_ref1 = classShelf[_name = (_ref2 = options.context) != null ? _ref2 : 'default']) != null ? _ref1 : classShelf[_name] = [];
      contextShelf.push({
        book: book,
        options: options
      });
      if (options.priority != null) {
        contextShelf.sort(function(a, b) {
          var _ref3, _ref4;

          return ((_ref3 = b.options.priority) != null ? _ref3 : 0) - ((_ref4 = a.options.priority) != null ? _ref4 : 0);
        });
      }
      return book;
    };

    Library.prototype.get = function(obj, options) {
      var book, result, _ref, _ref1;

      if (options == null) {
        options = {};
      }
      book = (_ref = this._get(obj, obj.constructor, (_ref1 = options.context) != null ? _ref1 : this._defaultContext, options)) != null ? _ref : this._get(obj, obj.constructor, 'default', options);
      if (book != null) {
        result = this.options.handler(obj, book, options);
      }
      this.emit('got', result, obj, book, options);
      return result;
    };

    Library.prototype._get = function(obj, klass, context, options) {
      var bookId, contextShelf, record, _i, _len, _ref;

      bookId = Library._classId(klass);
      contextShelf = (_ref = this.bookcase[bookId]) != null ? _ref[context] : void 0;
      if (contextShelf != null) {
        for (_i = 0, _len = contextShelf.length; _i < _len; _i++) {
          record = contextShelf[_i];
          if (match(obj, record, options.attributes)) {
            return record.book;
          }
        }
      }
      if (klass.__super__ != null) {
        return this._get(obj, klass.__super__.constructor, context, options);
      }
    };

    Library.prototype.withContext = function(context) {
      var newLibrary;

      newLibrary = new Object(this);
      newLibrary._defaultContext = context;
      return newLibrary;
    };

    Library.prototype.newEventBindings = function() {
      var newLibrary;

      newLibrary = new Object(this);
      newLibrary._events = {};
      return newLibrary;
    };

    Library.classKey = "__janus_classId" + (new Date().getTime());

    Library.classMap = {};

    Library._classId = function(klass) {
      var id;

      id = klass[this.classKey];
      if ((id != null) && this.classMap[id] === klass) {
        return klass[this.classKey];
      } else {
        id = util.uniqueId();
        this.classMap[id] = klass;
        return klass[this.classKey] = id;
      }
    };

    return Library;

  })(Base);

  match = function(obj, record, attributes) {
    var isMatch, _base;

    if ((typeof (_base = record.options).rejector === "function" ? _base.rejector(obj) : void 0) === true) {
      return false;
    }
    if ((record.options.acceptor != null) && (record.options.acceptor(obj) !== true)) {
      return false;
    }
    isMatch = true;
    if (attributes) {
      util.traverse(attributes, function(subpath, value) {
        if (util.deepGet(record.options.attributes, subpath) !== value) {
          return isMatch = false;
        }
      });
    }
    return isMatch;
  };

  util.extend(module.exports, {
    Library: Library
  });

}).call(this);
