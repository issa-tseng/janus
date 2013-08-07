util = require('../../util/util')
ViewContainer = require('./view-container').ViewContainer

class VaryingView extends ViewContainer
  _render: ->
    dom = super()

    # handler
    handleValue = (newValue) =>
      # clear out the current view if there is one.
      if this._value?
        dom.empty()
        this._removeView(this._value)

      # render a new view if there is one.
      if newValue?
        newView = this._getView(newValue)

        if newView?
          dom.append(newView.artifact())
          newView.emit('appended')

      # save off our new stuff
      this._value = newValue

    # kick off handlers.
    this.subject.on('changed', handleValue)
    handleValue(this.subject.value)

    # return dom.
    dom

util.extend(module.exports,
  VaryingView: VaryingView
)

