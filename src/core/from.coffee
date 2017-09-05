{ Varying } = require('./varying')
{ defcase, match, otherwise } = require('./case')
{ immediate, identity } = require('../util/util')

# TODO:
# * question: how should varying external cases be handled? right now they are
#   mostly unspecial and get handed through on point, and we don't really turn
#   anything into a final result/internal varying until a bare Varying is
#   returned from a point operation. is this right? also, currently the way
#   things are written varying is a required external case. that seems weird.


# util.
conj = (x, y) -> x.concat([ y ])
internalCases = ic = defcase('org.janusjs.core.from.internal', 'varying', 'map', 'flatMap', 'resolve')

# default applicants:
defaultCases = dc = defcase('org.janusjs.core.from.default', 'dynamic', 'watch', 'resolve', 'attribute', 'varying', 'app', 'self')

# val wraps proxies of Varyings. so you can perform maps or call conjunctions on them.
val = (conjunction, applicants = []) ->
  result = {}

  result.map = (f) ->
    [ rest..., last ] = applicants
    val(conjunction, conj(rest, internalCases.map( inner: last, f: f )))

  result.flatMap = (f) ->
    [ rest..., last ] = applicants
    val(conjunction, conj(rest, internalCases.flatMap( inner: last, f: f )))

  result.watch = (attr, orElse = null) ->
    [ rest..., last ] = applicants
    f = (obj) -> obj?.watch?(attr) ? orElse
    val(conjunction, conj(rest, internalCases.flatMap( inner: last, f: f )))

  result.resolve = (attr) ->
    [ rest..., last ] = applicants
    val(conjunction, conj(rest, internalCases.resolve( inner: last, attr: attr )))

  result.attribute = (attr) ->
    [ rest..., last ] = applicants
    f = (obj) -> obj?.attribute?(attr)
    val(conjunction, conj(rest, internalCases.map( inner: last, f: f )))

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


# helper for point() that processes our intermediate maps within one applicant chain.
mappedPoint = match(
  ic.map ({ inner, f }, point) ->
    match(
      ic.varying (x) -> ic.varying(x.map(f))
      otherwise -> ic.map({ inner, f })
    )(mappedPoint(inner, point))

  ic.flatMap ({ inner, f }, point) ->
    match(
      ic.varying (x) -> ic.varying(x.flatMap(f))
      otherwise -> ic.flatMap({ inner, f })
    )(mappedPoint(inner, point))

  ic.resolve ({ inner, attr }, point) ->
    match(
      ic.varying (x) -> ic.varying(x.flatMap((obj) -> point(from.default.app()).flatMap((app) -> obj.resolve(attr, app)) if obj?))
      otherwise -> ic.resolve({ inner, f })
    )(mappedPoint(inner, point))

  ic.varying (x) -> ic.varying(x) # TODO: rewrapping is slow.

  otherwise (x, point) ->
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

# helper that applies accumulated maps across applicants to a varying.
# TODO: recompiling matches is slow. also, relies on weird side effects.
applyMaps = (applicants, maps) ->
  [ first, rest... ] = maps

  # first we need to get a root Varying with which to chain our (flat)Maps onto.
  # if we have a single applicant we can just use that Varying directly. if we
  # don't we either use the first (flat)MapAll as a ComposedVarying root, or we
  # fabricate one based on a sane default.
  v =
    if applicants.length is 1
      # this mutation feels dirty but it's better than duplicating the
      # map-matcher already extant below.
      rest.unshift(first) if first?

      matchFinal(applicants[0])
    else
      # if nothing is specified, turn the result into an array.
      first ?= ic.map((args...) -> args)

      match(
        ic.map (f) -> Varying.mapAll.apply(null, (matchFinal(x) for x in applicants).concat([ f ]))
        ic.flatMap (f) -> Varying.flatMapAll.apply(null, (matchFinal(x) for x in applicants).concat([ f ]))
        otherwise -> throw 1
      )(first)

  # now chain on all our (flat)MapAlls.
  apply = match(
    ic.map (x) -> v.map(x)
    ic.flatMap (x) -> v.flatMap(x)
    otherwise -> throw 1
  )
  (v = apply(m)) for m in rest
  v

# used for .all.plain
plainMap = match(
  dc.dynamic (x) -> Varying.ly(x)
  dc.varying (x) -> Varying.ly(x)
  otherwise (x) -> x
)

# terminus gives you a representation of the entire chain. mapping at this level
# gives you all mapped values directly in the arg list.
terminus = (applicants, maps = []) ->
  result = (f) -> terminus(applicants, maps.concat([ ic.flatMap(f) ]))
  result.flatMap = (f) -> terminus(applicants, maps.concat([ ic.flatMap(f) ]))
  result.map = (f) -> terminus(applicants, maps.concat([ ic.map(f) ]))

  result.point = (f) -> terminus(mappedPoint(x, f) for x in applicants, maps)

  result.react = (f_) -> applyMaps(applicants, maps).react(f_)
  result.reactLater = (f_) -> applyMaps(applicants, maps).reactLater(f_)

  result.plain = -> result.point(plainMap)

  result.all = result

  # TODO: is this a good idea? feels like not.
  result.get = -> matchFinal(mappedPoint(applicants[0], (->)))?.get()
  result.isVarying = true

  result

# now return the root obj.
from = build(defaultCases)
from.build = build
from.default = defaultCases


module.exports = from

