View = require('./view').View

class DomView extends View
  constructor: (@subject, @options = {}) ->
    super(@subject, @options)

  markup: -> (node.outerHTML for node in this.artifact()).join('')

  _render: ->
    dom = this.dom()
    this._bindings = this.preboundTemplate(dom, this.pointer())
    dom

  wireEvents: ->
    return if this._wired is true
    this._wired = true

    # first run our own:
    dom = this.artifact()
    dom.data?('view', this)
    this._wireEvents()

    # theoretically, all DomViews should set bindings. but if they don't, do nothing.
    if this._bindings?
      # then run any declarations from our template:
      binding.start() for binding in this._bindings when binding.start?

      # then run our children forever:
      this._subwires = for binding in this._bindings when binding.view?
        binding.view.react((view) -> view?.wireEvents())

    null

  _destroy: ->
    if this._artifact?
      for binding in this._bindings
        binding.view?.get()?.destroy()
        binding.stop()
      subwire.stop() for subwire in this._subwires if this._subwires?

      this._artifact.trigger?('destroying')
      this._artifact.remove()

  @build: (fragment, template, options = {}) ->
    class extends DomView
      dom: -> fragment.clone()
      preboundTemplate: template(fragment)
      @viewModelClass: options.viewModelClass
      _wireEvents: -> options.wireEvents?(this.artifact(), this.subject, this)

module.exports = { DomView }

