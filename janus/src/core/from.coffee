{ Varying } = require('./varying')
cases = require('./types').from
{ match, otherwise } = require('./case')
{ fix, identity } = require('../util/util')

# we use these so that the from objects are not plain objects, so they don't get
# assign piecemeal if they're ever added to a Map.
FromVal = (->)
FromTerminus = (->)
class FromRoot

# helpers to help with point resolution on the applicant chains. the first is
# used by the intermediate mapping transformers, the second is use by the root.
tryApply = (x, f) -> (point) ->
  if (result = x(point))?.isVarying is true then f(result)
  else tryApply(result, f)

tryPoint = (kase) -> fix((wrapped) -> (point) ->
  if (result = point(kase))?.isVarying is true then result
  else wrapped
)

# a val represents a /single value/ in the fromchain. it does keep track of the
# rest (previous elements) of the chain in the rest parameter.
val = (conjunction, applicant, rest = []) ->
  append = (f) -> val(conjunction, tryApply(applicant, f), rest)
  applicants = rest.concat(applicant)

  (FromVal = (->)).prototype = {
    map: (f) -> append((v) -> v.map(f))
    flatMap: (f) -> append((v) -> v.flatMap(f))

    get: (attr) -> append((v) -> v.flatMap((x) -> x?.get?(attr) ? null))
    attribute: (attr) -> append((v) -> v.map((x) -> x?.attribute?(attr) ? null))
    pipe: (f) -> append(f)
    asVarying: -> append((v) -> new Varying(v))

    all: terminus(applicants)
    and: conjunction(applicants)
  }
  new FromVal()

# build takes a set of cases and makes from.method()s out of them.
build = (cases) ->
  methods = new FromRoot()
  makeVal = (kase) -> (applicants) -> (x) -> val(conjunction, tryPoint(kase(x)), applicants)
  (methods[name] = makeVal(kase)) for name, kase of cases when name isnt 'dynamic'

  base = if cases.dynamic? then makeVal(cases.dynamic) else (-> new FromRoot())
  conjunction = (applicants) ->
    result = base(applicants)
    result[k] = v(applicants) for k, v of methods
    result

  conjunction()

# the terminus gathers the vals together and allows map/mapAll on the result,
# and .point() resolution to actual Varyings, in either order.
# reifies to an actual Varying upon .point().
terminus = (applicants, map = identity) ->
  FromTerminus.prototype = {
    map: (f) -> terminus(applicants, (x) -> map(x).map(f))
    flatMap: (f) -> terminus(applicants, (x) -> map(x).flatMap(f))

    point: (f = identity) -> # TODO: tidy but slowish
      applied = (applicant?(f) ? applicant for applicant in applicants)
      v = # for performance/simplicity of resulting product:
        if applicants.length is 1 then map(Varying.of(applied[0]))
        else map(Varying.all(Varying.of(applicant) for applicant in applied))
      v.point = terminus(applied, map).point
      v
  }

  result = new FromTerminus()
  result.all = result
  result

from = build(cases)
from.build = build
module.exports = from

