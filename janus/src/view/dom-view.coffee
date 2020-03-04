{ Base } = require('../core/base')
View = require('./view').View
{ List } = require('../collection/list')
{ identity } = require('../util/util')

class DomView extends View
  constructor: (@subject, @options = {}) ->
    super(@subject, @options)

  markup: -> (node.outerHTML for node in this.artifact()).join('')

  _render: ->
    dom = this.dom()
    this._bindings = this.preboundTemplate(dom, this.pointer())
    this.emit('bound')
    dom

  attach: (dom) ->
    this._artifact = dom
    this._attach(dom)
    dom

  _attach: (dom) ->
    this._bindings = this.preboundTemplate(dom, this.pointer(), false)
    this.emit('bound')
    return

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
        this.reactTo(binding.view, (view) -> view?.wireEvents())
    return
  _wireEvents: -> # implement me!

  # actually implement the subviews methods:
  subviews: ->
    (this.subviews$ ?= Base.managed(=>
      subviews = new List()
      populate = => subviews.add(binding.view for binding in this._bindings when binding.view?)
      if this._bindings? then populate()
      else this.on('bound', populate)
      subviews.flatMap(identity).filter((x) -> x?) # TODO: List[Varying[T]] -> List[T]
    ))()
  subviews_: ->
    return [] unless this._bindings?
    return (view for binding in this._bindings when (view = binding.view?.get())?)

  __destroy: ->
    if this._bindings?
      for binding in this._bindings
        binding.view?.get()?.destroy()
        binding.stop()

    if this._subwires?
      subwire.stop() for subwire in this._subwires

    if this._artifact?
      this._artifact.trigger?('destroying')
      this._artifact.remove()
    else
      this._artifact = '' # never allow an artifact to be created.

    return

  @build: (x, y, z) ->
    if arguments.length is 3
      viewModelClass = x
      fragment = y
      template = z
    else
      fragment = x
      template = y

    class extends this
      dom: -> fragment.clone()
      preboundTemplate: template(fragment)

      @viewModelClass = viewModelClass if viewModelClass?
      @fragment: fragment
      @template: template

module.exports = { DomView }

