# Mutators have gone through a few revisions; philosophy on where state management
# should occur shifts back and forth between Mutators and Templates fairly readily.
# The current approach is heavily biased towards having Templates manage most of
# the work. This is largely based on the notion that it's dom fragment creation and
# selector search that is computationally expensive, not the creation of work
# against that dom node.
#
# This means Mutators become simply functions that, after declarative definition
# (eg `attr('href', from('someproperty'))`) they simply return a function of
# signature (dom, point) -> Varied. Thus they're repeatedly callable with units of
# side effect computation that can be easily canceled.

{ Varying } = require('../core/varying')
from = require('../core/from')
{ isFunction, extendNew } = require('../util/util')


# util.
safe = (x) -> if isFunction(x?.toString) then x.toString() else ''
doPoint = (x, point) ->
  if x?.point?
    x.point(point)
  else if x?.all?
    x.all.point(point)
  else
    Varying.ly(x)

mutators =
  attr: (prop, data) -> (dom, point) -> data.all.point(point).react((x) -> dom.attr(prop, safe(x)))

  classGroup: (prefix, data) -> (dom, point) ->
    data.all.point(point).react((x) ->
      existing = dom.attr('class')?.split(/[ ]+/) ? []
      dom.removeClass(y) for y in existing when y.indexOf(prefix) is 0
      dom.addClass("#{prefix}#{safe(x)}")
    )

  classed: (name, data) -> (dom, point) -> data.all.point(point).react((x) -> dom.toggleClass(name, x is true))

  css: (prop, data) -> (dom, point) -> data.all.point(point).react((x) -> dom.css(prop, safe(x)))

  text: (data) -> (dom, point) -> data.all.point(point).react((x) -> dom.text(safe(x)))

  html: (data) -> (dom, point) -> data.all.point(point).react((x) -> dom.html(safe(x)))

  prop: (prop, data) -> (dom, point) -> data.all.point(point).react((x) -> dom.prop(prop, x))

  render: (data, args = {}) ->
    # TODO: eventually should analyze the view that may be already there and see if
    # it's already appropriate, in which case do nothing (for the attach case).
    result = (dom, point) ->
      _vendView = (subject, context, app, criteria, options) -> app.vendView(subject, extendNew(criteria ? {}, { context, options }))

      Varying.flatMapAll(_vendView, data.all.point(point), doPoint(args.context, point), doPoint(from.app(), point), doPoint(args.criteria, point), doPoint(args.options, point)).react((view) ->
        this.view ?= new Varying()
        this.view.get()?.destroy()
        dom.empty()

        dom.append(view.artifact()) if view?
        this.view.set(view)
      )

    result.context = (context) -> mutators.render(data, extendNew(args, { context }))
    result.criteria = (criteria) -> mutators.render(data, extendNew(args, { criteria }))
    result.options = (options) -> mutators.render(data, extendNew(args, { options }))

    result

  # a bit dirty, but it is efficient and predictable.
  on: (args...) -> (dom, point) -> from.self().all.point(point).react((view) ->
    f_ = args[args.length - 1]
    g_ = (event) -> f_(event, view.subject, view, view.artifact())
    thisArgs = args.slice(0, -1)
    thisArgs.push(g_)
    this.start = =>
      dom.on(thisArgs...)
      this.stop = ->
        dom.off(thisArgs[0], g_)
        this.constructor.prototype.stop.call(this)
  )


module.exports = mutators

