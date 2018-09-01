# Mutators are dirt simple: they are simply functions that, after declarative
# definition (eg `attr('href', from('someproperty'))`), return a function of
# signature (dom, point, immediate) -> Observation. Thus they're repeatedly
# callable with units of side effect computation that can be easily canceled.

{ Varying } = require('../core/varying')
from = require('../core/from')
{ isFunction } = require('../util/util')


# util.
safe = (x) -> if isFunction(x?.toString) then x.toString() else ''
doPoint = (x, point) ->
  if x?.point?
    x.point(point)
  else if x?.all?
    x.all.point(point)
  else
    Varying.of(x)

mutators =
  attr: (prop, data) -> (dom, point, immediate = true) ->
    data.all.point(point).react(immediate, (x) -> dom.attr(prop, safe(x)))

  classGroup: (prefix, data) -> (dom, point, immediate = true) ->
    data.all.point(point).react(immediate, (x) ->
      existing = dom.attr('class')?.split(/ +/) ? []
      desired = ''
      (desired += "#{str} ") for str in existing when !str.startsWith(prefix)
      desired += "#{prefix}#{safe(x)}"
      dom.attr('class', desired)
    )

  classed: (name, data) -> (dom, point, immediate = true) ->
    data.all.point(point).react(immediate, (x) -> dom.toggleClass(name, x is true))

  css: (prop, data) -> (dom, point, immediate = true) ->
    data.all.point(point).react(immediate, (x) -> dom.css(prop, safe(x)))

  text: (data) -> (dom, point, immediate = true) ->
    data.all.point(point).react(immediate, (x) -> dom.text(safe(x)))

  html: (data) -> (dom, point, immediate = true) ->
    data.all.point(point).react(immediate, (x) -> dom.html(safe(x)))

  prop: (prop, data) -> (dom, point, immediate = true) ->
    data.all.point(point).react(immediate, (x) -> dom.prop(prop, x))

  render: (data, args = {}) ->
    result = (dom, point, immediate = true) ->
      getView = Varying.lift((subject, context, app, criteria, options) ->
        app.view(subject, Object.assign({ context }, criteria), options)
      )

      # despite the nomenclature we /always/ react immediately here, since
      # we do need to initialize the entire dom tree. instead, the immediate flag
      # gates whether we render or attach the first view we see.
      getView(data.all.point(point), doPoint(args.context, point), doPoint(from.app(), point), doPoint(args.criteria, point), doPoint(args.options, point)).react(true, (view) ->
        runBefore = this.view?
        this.view ?= new Varying()
        this.view.get()?.destroy()

        children = dom.children()
        if (immediate is false) and (runBefore is false) and (children.length > 0)
          view.attach(children) if view?
        else
          dom.empty()
          dom.append(view.artifact()) if view?

        this.view.set(view) # we wait to set so that the dom is part of the tree when events go.
      )

    result.context = (context) -> mutators.render(data, Object.assign({}, args, { context }))
    result.criteria = (criteria) -> mutators.render(data, Object.assign({}, args, { criteria }))
    result.options = (options) -> mutators.render(data, Object.assign({}, args, { options }))

    result

  # a bit dirty, but it is efficient and predictable.
  on: (args...) -> (dom, point) -> from.self().all.point(point).react((view) ->
    f_ = args[args.length - 1]
    g_ = (event) -> f_(event, view.subject, view, view.artifact())
    thisArgs = args.slice(0, -1)
    thisArgs.push(g_)
    this.start = (=>
      dom.on(thisArgs...)
      this.stop = (->
        dom.off(thisArgs[0], g_)
        this.constructor.prototype.stop.call(this)
        return
      )
    )
    return
  )


module.exports = mutators

