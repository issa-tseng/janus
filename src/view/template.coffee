defaultMutators = require('./mutators')


# wrap given mutators with a find() facility that records a selector and enables
# chaining of the mutator if provided, returning (dom) -> (point) -> Varied.
_recurse = (m, selector) ->
  result = (dom) ->
    target = dom.find(selector)
    (point) -> m(target, point)
  for k, v of m
    do (v) -> result[k] = (args...) -> _recurse(v(args...), selector)
  result

build = (mutators) -> (selector) -> _recurse(mutators, selector)

find = build(defaultMutators)
find.build = build

# templates are collections of mutations. they are immutable and just declarative.
# in fact, all template() does remember a bunch of functions and recursively call
# them all later. after pointing, it returns an array of the resulting `Varied`s.
template = (xs...) -> (dom) ->
  found = (x(dom) for x in xs)
  (point) -> Array.prototype.concat.apply([], (f(point) for f in found))


module.exports = { find, template }

