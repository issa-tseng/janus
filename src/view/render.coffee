# we split the render mutator out into this file just because it's sort of big
# and sprawling for optimization reasons.

{ Varying } = require('../core/varying')
from = require('../core/from')

pointify = (x, point) -> x?.all?.point?(point) ? Varying.of(x)

getView = Varying.lift((app, subject, context, criteria, options, parent) ->
  app.view(subject, Object.assign({ context }, criteria), options, parent)
)
getView_subject = Varying.lift((app, subject, parent) -> app.view(subject, undefined, undefined, parent))
getView_subjectContext = Varying.lift((app, subject, context, parent) -> app.view(subject, { context }, undefined, parent))
getView_subjectCriteria = Varying.lift((app, subject, criteria, parent) -> app.view(subject, criteria, undefined, parent))
getView_subjectOptions = Varying.lift((app, subject, options, parent) -> app.view(subject, undefined, options, parent))

fromApp = from.app().all
fromSelf = from.self().all
render = (data, args = {}) ->
  result = (dom, point, immediate = true) ->
    view =
      if !args.context? and !args.criteria? and !args.options?
        getView_subject(fromApp.point(point), data.all.point(point), fromSelf.point(point))
      else if !args.criteria? and !args.options?
        getView_subjectContext(fromApp.point(point), data.all.point(point), pointify(args.context, point), fromSelf.point(point))
      else if !args.context? and !args.options?
        getView_subjectCriteria(fromApp.point(point), data.all.point(point), pointify(args.criteria, point), fromSelf.point(point))
      else if !args.context? and !args.criteria?
        getView_subjectOptions(fromApp.point(point), data.all.point(point), pointify(args.options, point), fromSelf.point(point))
      else
        getView(fromApp.point(point), data.all.point(point), pointify(args.context, point), pointify(args.criteria, point), pointify(args.options, point), fromSelf.point(point))

    # despite the nomenclature we /always/ react immediately here, since
    # we do need to initialize the entire dom tree. instead, the immediate flag
    # gates whether we render or attach the first view we see.
    view.react(true, (view_) ->
      runBefore = this.view?
      this.view ?= new Varying()
      this.view.get()?.destroy()

      children = dom.children()
      if (immediate is false) and (runBefore is false) and (children.length > 0)
        view_.attach(children) if view_?
      else
        dom.empty()
        dom.append(view_.artifact()) if view_?

      this.view.set(view_) # we wait to set so that the dom is part of the tree when events go.
    )

  result.context = (context) -> render(data, Object.assign({}, args, { context }))
  result.criteria = (criteria) -> render(data, Object.assign({}, args, { criteria }))
  result.options = (options) -> render(data, Object.assign({}, args, { options }))

  result

module.exports = render

