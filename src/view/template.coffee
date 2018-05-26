# Templates perform a number of operations to help merge multiple Mutators together
# against actual concrete dom trees:
# * aggregation of mutators and distribution of context-point.
# * aggregation of subtemplates.
# * learning and execution of selectors against dom fragments.
# Between Templates and Mutators, the total function signature is as follows:
# (Template|Mutator p, Varied v) => (p...) -> (dom) -> (dom, point) -> v

defaultMutators = require('./mutators')

# do a shuffle-dance to wrap a dom node so that .find() will select the root node
# as expected, but without assuming which jquery/zepto/etc library is being used.
wrap = (dom) ->
  dom.prepend('<div/>')
  wrapper = dom.children(':first-child')
  wrapper.remove()
  wrapper.append(dom)
  wrapper

# run our selectors and learn how to get to those elements in the fragment with
# simple tree-walks. this makes view generation faster as we can cache the selector
# work, and it makes re-attaching to already-rendered fragments easier because there
# won't be accidental child-matches we'd have to filter out.
selectorToWalks = (dom, selector) ->
  rawDom = dom.get(0)
  dom.find(selector).map((_, target) ->
    walk = []
    while (parent = target.parentNode) isnt rawDom
      for idx in [0..parent.childNodes.length] when parent.childNodes[idx] is target
        walk.unshift(idx)
        break
      target = parent
    [ walk ] # need to renest so jquery does not flatten grrr
  )

# given the walk we record above, perform that walk on a domtree to reacquire a
# selection of the desired nodes. because jquery/zepto map actually return their
# own specialist collections upon .map(), we end up with a selection again.
walk = (dom, walks) ->
  rawDom = dom.get(0)
  walks.map((_, walk) ->
    ptr = rawDom
    (ptr = ptr.childNodes[idx]) for idx in walk
    ptr
  )

# allow find() to perform chaining of the mutator if provided, returning
# (fragment) -> (dom, point) -> Varied. we give the fragment (the canonical html
# as defined by the template) followed separately by the actual dom instance so that
# we can learn the walks, then apply them against the actual dom.
#
# TODO: we wrap our fragment here so that the behavior works even if find() is used
# on its own. but that means we're redoing the work many times.
rechain = (chains, mutators, selector) ->
  # prebind if called with fragment (locks the chain).
  result = (fragment) ->
    walks = selectorToWalks(wrap(fragment), selector)
    (dom, point) ->
      target = walk(dom, walks)
      chain(target, point) for chain in chains

  # first decorate anything specific to the present chain.
  [ head..., tail ] = chains
  if tail?
    for k, v of tail
      do (v) -> result[k] = (args...) -> rechain(head.concat([ v(args...) ]), mutators, selector)

  # now decorate anything nonconflicting from our base set.
  for k, v of mutators when !result[k]?
    do (v) -> result[k] = (args...) -> rechain(chains.concat([ v(args...) ]), mutators, selector)

  result

# build creates a find()er with the given mutators as chaining options. we then
# build against our default mutators to provide a default find(), and then decorate
# build() onto that find to allow userland custom find()s.
build = (mutators) -> (selector) -> rechain([], mutators, selector)
find = build(defaultMutators)
find.build = build

# templates are collections of mutations. they are immutable and just declarative.
# in fact, all template() does remember a bunch of functions and recursively call
# them all later. after pointing, it returns an array of the resulting `Varied`s.
template = (xs...) -> (fragment) ->
  prebound = (x(fragment) for x in xs)
  (dom, point) -> Array.prototype.concat.apply([], (f(dom, point) for f in prebound))


module.exports = { find, template }

