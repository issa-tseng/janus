{ Varying } = require('./varying')
{ caseSet, match, otherwise } = require('./case')
{ immediate, identity } = require('../util/util')

# TODO:
# * question: how should varying external cases be handled? right now they are
#   mostly unspecial and get handed through on point, and we don't really turn
#   anything into a final result/internal varying until a bare Varying is
#   returned from a point operation. is this right? also, currently the way
#   things are written varying is a required external case. that seems weird.

# util.
conj = (x, y) -> x.concat([ y ])
internalCases = ic = caseSet('varying', 'map', 'flatMap')

# default applicants:
defaultCases = caseSet('dynamic', 'watch', 'resolve', 'attribute', 'varying', 'app')

# val wraps proxies of Varyings. so you can perform maps or call conjunctions on them.
val = (conjunction, applicants = []) ->
  result = {}

  result.map = (f) ->
    [ rest..., last ] = applicants
    val(conjunction, conj(rest, internalCases.map( inner: last, f: f )))

  result.flatMap = (f) ->
    [ rest..., last ] = applicants
    val(conjunction, conj(rest, internalCases.flatMap( inner: last, f: f )))

  result.all = terminus(applicants)
  result.and = conjunction(applicants)

  result

# creates a conjunction with the relevant methods.
build = (cases) ->
  methods = {}
  for name, kase of cases when name isnt 'dynamic'
    do (name, kase) ->
      methods[name] = (applicants) -> (x) -> val(conjunction, conj(applicants, kase(x)))

  base = if cases.dynamic? then ((applicants) -> (x) -> val(conjunction, conj(applicants, cases.dynamic(x)))) else (-> {})

  # conjuctions let you start new applicants.
  conjunction = (applicants = []) ->
    result = base(applicants)
    result[k] = v(applicants) for k, v of methods

    result

  conjunction()


# helper for point() that processes our intermediate maps and such.
# TODO: defining a match per iteration is slow!
mappedPoint = (point) -> match(
  ic.map ({ inner, f }) ->
    match(
      ic.varying (x) -> ic.varying(x.map(f))
      otherwise -> ic.map({ inner, f })
    )(mappedPoint(point)(inner))

  ic.flatMap ({ inner, f }) ->
    match(
      ic.varying (x) -> ic.varying(x.flatMap(f))
      otherwise -> ic.flatMap({ inner, f })
    )(mappedPoint(point)(inner))

  ic.varying (x) -> ic.varying(x) # TODO: rewrapping is slow.

  otherwise (x) ->
    result = point(x)
    if result?.isVarying is true
      ic.varying(result)
    else
      x
)

# matcher that's run in order to finalize.
matchFinal = match(
  ic.varying (x) -> x
  otherwise (x) -> new Varying(x)
)

# helper that applies accumulated maps to a varying.
# TODO: as with above, perf. also, relies on weird side effects.
applyMaps = (applicants, maps) ->
  [ first, rest... ] = maps

  first ?= ic.flatMap(identity)

  v = match(
    ic.map (f) -> Varying.mapAll.apply(null, (matchFinal(x) for x in applicants).concat([ f ]))
    ic.flatMap (f) -> Varying.flatMapAll.apply(null, (matchFinal(x) for x in applicants).concat([ f ]))
    otherwise -> throw 1
  )(first)

  apply = match(
    ic.map (x) -> v.map(x)
    ic.flatMap (x) -> v.flatMap(x)
    otherwise -> throw 1
  )
  (v = apply(m)) for m in rest
  v

# terminus gives you a representation of the entire chain. mapping at this level
# gives you all mapped values directly in the arg list.
terminus = (applicants, maps = []) ->
  result = (f) -> terminus(applicants, maps.concat([ ic.flatMap(f) ]))
  result.flatMap = (f) -> terminus(applicants, maps.concat([ ic.flatMap(f) ]))
  result.map = (f) -> terminus(applicants, maps.concat([ ic.map(f) ]))

  result.point = (f) -> point = mappedPoint(f); terminus(point(x) for x in applicants, maps)

  result.react = (f_) -> applyMaps(applicants, maps).react(f_)
  result.reactNow = (f_) -> applyMaps(applicants, maps).reactNow(f_)

  # TODO: is this a good idea? feels like not.
  result.get = -> matchFinal(mappedPoint(->)(applicants[0]))?.get()
  result.isVarying = true

  result

# now return the root obj.
from = build(defaultCases)
from.build = build
from.default = defaultCases

module.exports = from

