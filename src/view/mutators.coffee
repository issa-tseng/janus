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
{ isPrimitive, extendNew } = require('../util/util')

# util.
safe = (x) -> if isPrimitive(x) then x.toString() else ''
terminate = (x) -> if x.point? then x else x.all
doPoint = (x, point) ->
  if x?.point?
    x.point(point)
  else if x?.all?
    x.all.point(point)
  else
    Varying.ly(x)

mutators =
  attr: (prop, data) -> (dom, point) -> terminate(data).point(point).reactNow((x) -> dom.attr(prop, safe(x)))

  classGroup: (prefix, data) -> (dom, point) ->
    terminate(data).point(point).reactNow (x) ->
      existing = dom.attr('class')?.split(/[ ]+/) ? []
      dom.removeClass(y) for y in existing when y.indexOf(prefix) is 0
      dom.addClass("#{prefix}#{safe(x)}")

  classed: (name, data) -> (dom, point) -> terminate(data).point(point).reactNow((x) -> dom.toggleClass(name, x is true))

  css: (prop, data) -> (dom, point) -> terminate(data).point(point).reactNow((x) -> dom.css(prop, safe(x)))

  text: (data) -> (dom, point) -> terminate(data).point(point).reactNow((x) -> dom.text(safe(x)))

  html: (data) -> (dom, point) -> terminate(data).point(point).reactNow((x) -> dom.html(safe(x)))

  render: (data, args = {}) ->
    result = (dom, point) ->
      _render = (subject, context, app, find, options) ->
        dom.data('subview')?.destroy()
        dom.empty()

        view = app.getView(subject, util.extendNew(find ? {}, context: context, constructorOpts: options))
        if view?
          dom.append(view.artifact())
          dom.data('subview', view)
          # TODO: do we have to inform the view it's been appended?

      Varying.pure(_render, terminate(data).point(point), doPoint(args.context), point('app'), doPoint(args.find), doPoint(args.options))

    result.context = (context) -> mutators.render(data, extendNew(args, context: context ))
    result.find = (find) -> mutators.render(data, extendNew(args, find: find ))
    result.options = (options) -> mutators.render(data, extendNew(args, options: options ))

    result

module.exports = mutators

