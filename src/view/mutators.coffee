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
    # TODO: eventually should analyze the view that may be already there and see if
    # it's already appropriate, in which case do nothing (for the attach case).
    result = (dom, point) ->
      _getView = (subject, context, app, find, options) -> app.getView(subject, extendNew(find ? {}, context: context, constructorOpts: options))

      Varying.flatMapAll(_getView, terminate(data).point(point), doPoint(args.context, point), doPoint(from.app(), point), doPoint(args.find, point), doPoint(args.options, point)).reactNow (view) ->
        dom.data('subview')?.destroy()
        dom.empty()
        return unless view?

        dom.append(view.artifact())
        view.emit?('appended') # tell it it's been appended. it will figure out for itself where to.
        dom.data('subview', view)

    result.context = (context) -> mutators.render(data, extendNew(args, { context }))
    result.find = (find) -> mutators.render(data, extendNew(args, { find }))
    result.options = (options) -> mutators.render(data, extendNew(args, { options }))

    result

module.exports = mutators

