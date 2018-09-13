Varying = require('../core/varying').Varying

foldBase = (update) -> (collection) ->
  result = new Varying(null)
  watched = 0

  collection.watchLength().react (length) ->
    for idx in [watched...length]
      do (idx) ->
        collection.watchAt(idx).react((value) -> result.set(update(value, idx, collection)))
    watched = length

  result

folds =
  apply: (collection, f) ->
    collection.watchLength().flatMap((length) ->
      Varying.all(collection.watchAt(idx) for idx in [0..collection.length]).map(f))

  join: (collection, joiner) -> foldBase((_, _2, collection) -> collection.list.join(joiner))(collection)

  scanl: (collection, memo, f) ->
    self = new Varying()
    result = collection.enumeration().flatMap((idx) -> self.flatMap((result) ->
      return unless result?
      prev = if idx is 0 then Varying.of(memo) else result.watchAt(idx - 1)
      Varying.mapAll(f, prev, collection.watchAt(idx))
    ))
    self.set(result)
    result

  foldl: (collection, memo, f) -> folds.scanl(collection, memo, f).watchAt(-1)

module.exports = folds

