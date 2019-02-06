Varying = require('../core/varying').Varying

foldBase = (update) -> (collection) ->
  result = new Varying(null)
  watched = 0

  collection.length.react (length) ->
    for idx in [watched...length]
      do (idx) ->
        collection.at(idx).react((value) -> result.set(update(value, idx, collection)))
    watched = length

  result

folds =
  apply: (collection, f) ->
    collection.length.flatMap((length) ->
      Varying.all(collection.at(idx) for idx in [0..collection.length]).map(f))

  join: (collection, joiner) -> foldBase((_, _2, collection) -> collection.list.join(joiner))(collection)

  scanl: (collection, memo, f) ->
    self = new Varying()
    result = collection.enumerate().flatMap((idx) -> self.flatMap((result) ->
      return unless result?
      prev = if idx is 0 then Varying.of(memo) else result.at(idx - 1)
      Varying.mapAll(f, prev, collection.at(idx))
    ))
    self.set(result)
    result

  foldl: (collection, memo, f) -> folds.scanl(collection, memo, f).at(-1)

module.exports = folds

