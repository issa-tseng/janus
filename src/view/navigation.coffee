{ isString, isNumber, isFunction, identity } = require('../util/util')
{ Varying } = require('../core/varying')
{ List } = require('../collection/list')

rewriteSelector = (selector, view) ->
  if (isString(selector) or isNumber(selector)) and view.subject?
    if (target = view.subject.get_?(selector))?
      return target
  return selector

match = (selector, view) ->
  if undefined is selector then true
  else if view is selector then true
  else if view?.subject is selector then true
  else if selector[Symbol.hasInstance]?
    if view instanceof selector then true
    else if view?.subject instanceof selector then true


################################################################################
# PARENT SELECTION

parent_ = (selector, view) ->
  candidate = view.options.parent
  return candidate if candidate and match(selector, candidate)

closest_ = (selector, view) ->
  candidate = view
  while (candidate = candidate.options.parent)?
    return candidate if match(selector, candidate)
  return

# parent(s) cannot change:
parent = (selector, view) -> new Varying(parent_(selector, view))
closest = (selector, view) -> new Varying(closest_(selector, view))


################################################################################
# CHILD SELECTION

# into/into_ will only return the first matching result, even if there are many.
into_ = (selector, view) ->
  selector = rewriteSelector(selector, view)
  for candidate in view.subviews_()
    return candidate if match(selector, candidate)
  return

# intoAll/intoAll_ returns all matching results.
intoAll_ = (selector, view) ->
  selector = rewriteSelector(selector, view)
  candidate for candidate in view.subviews_() when match(selector, candidate)

# TODO: better perf w transducer i guess?
into = (selector, view) -> intoAll(selector, view).get(0)

intoAll = (selector, view) ->
  selector = Varying.of(selector).flatMap((sel) ->
    if isNumber(sel) or isString(sel) and isFunction(view.subject?.get) then view.subject.get(sel)
    else sel
  )
  return view.subviews().filter((view) -> selector.map((s) -> match(s, view)))

module.exports = {
  match, # exported for testing only. TODO: hide from public API.
  parent_, closest_, into_, intoAll_,
  parent, closest, into, intoAll
}

