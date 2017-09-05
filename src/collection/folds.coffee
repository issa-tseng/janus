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
  any: foldBase (value, _, collection) ->
    if value isnt true
      existTrue = false
      for item in collection.list
        if item is true
          existTrue = true
          break

      existTrue
    else
      true

  find: foldBase (value, idx, collection) ->
    if value is true
      collection.list[idx]
    else
      for elem in collection
        return elem if f(elem) is true
      null

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

  # dangerous (stack depth)
  fold: (collection, memo, f) ->
    intermediate = []
    intermediate[-1] = Varying.ly(memo)

    update = (value, idx, collection) ->
      start = Math.min(intermediate.length, idx)
      for idx in [start...collection.list.length]
        intermediate[idx] = intermediate[idx - 1].map((last) -> f(last, value))
      intermediate[intermediate.length - 1]

    foldBase(update)(collection)

  scanl: (collection, memo, f) ->
    intermediate = new (require('./list').List)()
    intermediate.add(Varying.ly(memo))

    collection.watchLength().react (length) ->
      intermediateLength = intermediate.list.length - 1
      if length > intermediateLength
        for idx in [intermediateLength...length]
          do (idx) ->
            intermediate.add(Varying.combine([ intermediate.watchAt(idx), collection.watchAt(idx) ], f))
      else if length > intermediateLength
        for idx in [length...intermediateLength]
          intermediate.removeAt(intermediateLength)

    intermediate

  foldl: (collection, memo, f) -> folds.scanl(collection, memo, f).watchAt(-1)

module.exports = folds

