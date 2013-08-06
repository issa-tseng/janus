util = require('../../util/util')

DomView = require('../dom-view').DomView
reference = require('../../model/reference')
Varying = require('../../core/varying').Varying

class ViewContainer extends DomView

  _initialize: ->
    # track the views we've rendered by subject id.
    this._views = {}

    # init our childOpts in case we weren't given any.
    this.options.childOpts ?= {}

  _removeView: (subject) ->
    # kill the view; remove our ref.
    this._views[subject._id]?.destroy()
    delete this._views[subject._id]

    # mutation; return nothing.
    null

  _getView: (subject) ->
    # nothing to do for a null/undef subject.
    return null unless subject?

    debugger if subject instanceof Varying

    # get the view we want to render.
    view =
      if subject instanceof DomView
        this._subviews.add(subject)
        item
      else if this.options.itemView?
        result = new (this.options.itemView)(subject, util.extendNew(this.options.childOpts, { app: this.options.app }))
        this._subviews.add(result)
        result
      else
        this._app().getView(subject, context: this.options.itemContext, constructorOpts: this.options.childOpts)

    # remember it.
    this._views[subject._id] = view

    # wire it if we're already in that state.
    view?.wireEvents() if this._wired is true

    # return it.
    view

  # shouldn't be necessary:
  #_wireEvents: -> view.wireEvents() for _, view of this._views

util.extend(module.exports,
  ViewContainer: ViewContainer
)

