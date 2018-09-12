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

  min: (collection) ->
    last = null

    update = (value, idx, collection) ->
      last =
        if last is null
          value
        else if value <= last
          value
        else
          largest = null
          [ (largest = if largest? then Math.min(largest, x) else x) for x in collection.list ]
          last = largest

    foldBase(update)(collection)

  max: (collection) ->
    last = null

    update = (value, idx, collection) ->
      last =
        if last is null
          value
        else if value >= last
          value
        else
          largest = null
          [ (largest = if largest? then Math.max(largest, x) else x) for x in collection.list ]
          last = largest

    foldBase(update)(collection)

  sum: (collection) ->
    values = []
    last = 0

    update = (value, idx, collection) ->
      diff = (value ? 0) - (values[idx] ? 0)
      values[idx] = value
      last += diff

    foldBase(update)(collection)

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

