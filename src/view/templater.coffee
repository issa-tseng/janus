{ mutators } = require('./mutators')

# mutations encode single data-to-dom bindings, including the action that should
# occur in the dom.

class Mutation
  isMutation: true
  constructor: (@selector, @mutator) ->

# TODO: this feels stupid. there must be a better way?
# TODO: do i care about the possibility of namespace collisions?
build = (objs) ->
  methods = {}
  for obj in objs
    for name, klass of obj
      do (name, kase) ->
        methods[name] = (selector) -> (args...) -> new Mutation(selector, new klass(args...))

  (selector) ->
    result = { selector }
    result[k] = v(selector) for k, v of methods
    result

find = build(mutators)
find.build = build

# templates are collections of mutations. they are immutable and just declarative.

class Template
  isTemplate: true
  constructor: (@mutations) ->

  bind: (dom, point) -> new BoundTemplate(dom, this.mutations, point)

template = (mutations...) ->
  result = []

  for mutation in mutations
    if mutation.isMutation is true
      result.push(mutation)
    else
      result = result.concat(template(mutation))

  new Template(result)

# bound templates are created when a template is bound to a dom fragment. they
# do the actual binding and state management involved.

class BoundTemplate
  constructor: (@dom, @mutations, point) ->
    # weird shuffle dance to wrap the dom without referencing a framework, but
    # support jquery/zepto/cheerio. we can use wrap() if cheerio adds it.
    dom.prepend('<div/>')
    this.wrappedDom = wrapper = dom.children(':first')
    wrapper.remove()
    wrapper.append(dom)

    # now actually bind against our dom nodes.
    this.point(point)
    this._bind(point)

  _bind: (point) ->
    mutation.mutator.bind(this.wrappedDom.find(mutation.selector)) for mutation in this.mutations
    null

  point: (point) ->
    mutation.mutator.point(point) for mutation in this.mutations
    null

  destroy: ->
    mutation.mutator.stop() for mutation in this.mutations
    dom.trigger('destroying')
    null


module.exports = { template, find }

