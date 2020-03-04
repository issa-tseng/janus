{ Base } = require('../core/base')
{ Varying } = require('../core/varying')

scanl = (mapper) -> (collection, memo, f) ->
  self = new Varying()
  result = collection.enumerate().flatMap((idx) -> self.flatMap((result) ->
    return unless result?
    prev = if idx is 0 then Varying.of(memo) else result.at(idx - 1)
    Varying[mapper](f, prev, collection.at(idx))
  ))
  self.set(result)
  result

foldl = (mapper) ->
  scanner = scanl(mapper)
  (collection, memo, f) -> collection.length.flatMap((len) ->
    if len is 0 then new Varying(memo)
    else scanner(collection, memo, f).at(-1)
  )

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

  scanl: scanl('mapAll')
  flatScanl: scanl('flatMapAll')
  foldl: (collection, memo, f) -> foldl('mapAll')(collection, memo, f)
  flatFoldl: (collection, memo, f) -> foldl('flatMapAll')(collection, memo, f)

module.exports = folds

