# Mutators are dirt simple: they are simply functions that, after declarative
# definition (eg `attr('href', from('someproperty'))`), return a function of
# signature (dom, point, immediate) -> Observation. Thus they're repeatedly
# callable with units of side effect computation that can be easily canceled.

from = require('../core/from')
render = require('./render')
{ isFunction } = require('../util/util')


# util.
safe = (x) -> if isFunction(x?.toString) then x.toString() else ''

mutators = {
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

  render

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
}


module.exports = mutators

