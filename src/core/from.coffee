{ Varying } = require('./varying')
{ caseSet, match, otherwise } = require('./case')
{ immediate } = require('../util/util')

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
defaultCases = caseSet('dynamic', 'attr', 'definition', 'varying')

# val wraps proxies of Varyings. so you can perform maps or call conjunctions on them.
val = (conjunction, applicants = []) ->
  result = {} # ????

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
  for name, kase of cases when name not in [ 'dynamic', 'varying' ]
    do (name, kase) ->
      methods[name] = (applicants) -> (args...) -> val(conjunction, conj(applicants, kase(args)))

  methods.varying = (applicants) -> (f) -> val(conjunction, conj(applicants, cases.varying(f)))
  base = if cases.dynamic? then ((applicants) -> (args...) -> val(conjunction, conj(applicants, cases.dynamic(args)))) else (-> {})

  # conjuctions let you start new applicants.
  conjunction = (applicants = []) ->
    result = base(applicants)
    result[k] = v(applicants) for k, v of methods

    result

  conjunction()


  # TODO: reject identically named cases from other sets; diagnose things getting wrapped as varying that aren't

# helper for point() that processes our intermediate maps and such.
mappedPoint = (point) -> match(
  ic.map ({ inner, f }) ->
    inner = mappedPoint(point)(inner)
    if inner?.isVarying is true
      ic.varying(inner.map(f))
    else
      ic.map({ inner, f })

  ic.flatMap ({ inner, f }) ->
    inner = mappedPoint(point)(inner)
    if inner?.isVarying is true
      ic.varying(inner.flatMap(f))
    else
      ic.flatMap({ inner, f })

  ic.varying (x) -> ic.varying(x) # TODO: rewrapping is slow.

  otherwise (x) ->
    result = point(x)
    if result?.isVarying is true
      ic.varying(result)
    else
      x
)

matchFinal = match(
  ic.varying (x) -> x
  otherwise (x) -> new Varying(x)
)

# terminus gives you a representation of the entire chain. mapping at this level
# gives you all mapped values directly in the arg list.
terminus = (applicants) ->
  apply = (m) -> (f) ->
    applying = (matchFinal(x) for x in applicants)
    m.apply(null, applying.concat([ f ]))

  result = apply(Varying.flatMapAll)
  result.point = (f) -> point = mappedPoint(f); terminus(point(x) for x in applicants)
  result.flatMap = apply(Varying.flatMapAll)
  result.map = apply(Varying.mapAll)

  result

# now return the root obj.
from = build(defaultCases)
from.build = build
from.default = defaultCases

module.exports = from

