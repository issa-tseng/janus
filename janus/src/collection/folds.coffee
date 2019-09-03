{ Base } = require('../core/base')
{ Varying } = require('../core/varying')

folds =
  apply: (collection, f) ->
    collection.length.flatMap((length) ->
      Varying.all(collection.at(idx) for idx in [0..collection.length_]).map(f))

  join: (collection, joiner) -> Varying.managed(
    -> new Base(),
    (listener) ->
      result = new Varying()
      update = -> result.set(collection.list.join(joiner))
      listener.listenTo(collection, 'added', update)
      listener.listenTo(collection, 'moved', update)
      listener.listenTo(collection, 'removed', update)
      result
  )

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

