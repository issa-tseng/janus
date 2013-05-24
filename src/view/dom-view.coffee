# The **DomView** is a `View` that makes some assumptions about its own use:
#
# * It will rely on the Janus `Templater` for rendering.
# * It returns a DOM node.
#

util = require('../util/util')
View = require('./view').View

class DomView extends View
  # When deriving from DomView, set the templater class to determine which
  # templater to use.
  templateClass: null

  # By default, the render action for a `DomView` is simply to render out the
  # DOM via our templater and attach the binder against what we know is our
  # primary data.
  _render: ->
    this._templater = new this.templateClass( viewLibrary: this.options.viewLibrary )

    dom = this._templater.dom()
    this._templater.data(this.subject)
    dom

  # Since we're opinionated enough here to explicitly be dealing with DOM, we
  # can also expose a `markup()` for grabbing the actual HTML.
  markup: -> (node.outerHTML for node in this.artifact().get()).join('')

  _bind: (dom) ->
    this._templater = new this.templateClass(
      viewLibrary: this.options.viewLibrary
      dom: dom
      bindOnly: true
    )

    this._templater.data(this.subject)
    null


util.extend(module.exports,
  DomView: DomView
)

