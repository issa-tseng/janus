// Generated by CoffeeScript 1.12.2
(function() {
  var Base, Varying, foldl, folds, scanl;

  Base = require('../core/base').Base;

  Varying = require('../core/varying').Varying;

  scanl = function(mapper) {
    return function(collection, memo, f) {
      var result, self;
      self = new Varying();
      result = collection.enumerate().flatMap(function(idx) {
        return self.flatMap(function(result) {
          var prev;
          if (result == null) {
            return;
          }
          prev = idx === 0 ? Varying.of(memo) : result.at(idx - 1);
          return Varying[mapper](f, prev, collection.at(idx));
        });
      });
      self.set(result);
      return result;
    };
  };

  foldl = function(mapper) {
    var scanner;
    scanner = scanl(mapper);
    return function(collection, memo, f) {
      return collection.length.flatMap(function(len) {
        if (len === 0) {
          return new Varying(memo);
        } else {
          return scanner(collection, memo, f).at(-1);
        }
      });
    };
  };

  folds = {
    apply: function(collection, f) {
      return collection.length.flatMap(function(length) {
        var idx;
        return Varying.all((function() {
          var i, ref, results;
          results = [];
          for (idx = i = 0, ref = collection.length_; 0 <= ref ? i <= ref : i >= ref; idx = 0 <= ref ? ++i : --i) {
            results.push(collection.at(idx));
          }
          return results;
        })()).map(f);
      });
    },
    join: function(collection, joiner) {
      return Varying.managed(function() {
        return new Base();
      }, function(listener) {
        var result, update;
        result = new Varying();
        update = function() {
          return result.set(collection.list.join(joiner));
        };
        listener.listenTo(collection, 'added', update);
        listener.listenTo(collection, 'moved', update);
        listener.listenTo(collection, 'removed', update);
        return result;
      });
    },
    scanl: scanl('mapAll'),
    flatScanl: scanl('flatMapAll'),
    foldl: function(collection, memo, f) {
      return foldl('mapAll')(collection, memo, f);
    },
    flatFoldl: function(collection, memo, f) {
      return foldl('flatMapAll')(collection, memo, f);
    }
  };

  module.exports = folds;

}).call(this);
