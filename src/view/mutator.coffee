{ Varying } = require('../core/varying')
{ isPrimitive, extendNew, identity } = require('../util/util')

from = require('../core/from')
{ caseSet, match, otherwise } = require('../core/case')

{ attr, classGroup, classed, css, text, html, render } = operations = caseSet('attr', 'classGroup', 'classed', 'css', 'text', 'html', 'render')

# util.
safe = (x) -> if isPrimitive(x) then x.toString() else ''

promote = (x) ->
  if x.react?
    x
  else if x.all?
    promote(x.all)

# base mutator class. state is managed as internally as possible. overriden
# parts are largely static, which the exception of custom binding methodologies
# like chaining.
class Mutator
  constructor: (binding) ->
    this._bindings = [ binding ]

  bind: (artifact) ->
    this._artifact = artifact
    this._start()
    null

  point: (point, app) ->
    this._point = point
    this._app = app
    this._start()
    null

  _start: ->
    this.stop()
    return unless this._artifact?

    pointed = ( promote(binding).point(this._point ? (-> new Varying())) for binding in this.bindings() )
    this._bound = Varying.flatMapAll.apply(null, pointed.concat([ this.exec() ])).reactNow((f) => f(this._artifact, this._app))

    null

  stop: ->
    this._bound?.stop()
    null

  bindings: -> this._bindings

  exec: -> this.constructor.exec
  @exec: ->

Mutator0 = Mutator
class Mutator1 extends Mutator
  constructor: (@_param, binding) -> super(binding)
  exec: -> this.constructor.exec(@_param)


# here are our standard mutators.

mutators =
  attr:
    class AttrMutator extends Mutator1
      @exec: (attr) -> (x) -> (dom) -> dom.attr(attr, safe(x))

  classGroup:
    class ClassGroupMutator extends Mutator1
      @exec: (prefix) -> (x) -> (dom) ->
        existing = dom.attr('class')?.split(' ') ? []
        dom.removeClass(className) for className in existing when className.indexOf(prefix) is 0
        dom.addClass("#{prefix}#{x}") if isPrimitive(x) is true

  classed:
    class ClassMutator extends Mutator1
      @exec: (className) -> (x) -> (dom) -> dom.toggleClass(className, x is true)

  css:
    class CssMutator extends Mutator1
      @exec: (prop) -> (x) -> (dom) -> dom.css(prop, safe(x))

  text:
    class TextMutator extends Mutator0
      @exec: (x) -> (dom) -> dom.text(safe(x))

  html:
    class HtmlMutator extends Mutator0
      @exec: (x) -> (dom) -> dom.html(safe(x))

  render:
    class RenderMutator extends Mutator
      constructor: (subject, bindings = {}) ->
        this._bindings =
          if bindings.subject?
            extendNew(bindings, { subject: subject })
          else
            bindings

      context: (context) -> new RenderMutator(this._bindings.subject, extendNew(bindings, context: context ))
      library: (library) -> new RenderMutator(this._bindings.subject, extendNew(bindings, library: library ))
      options: (options) -> new RenderMutator(this._bindings.subject, extendNew(bindings, options: options ))

      start: ->
        this.stop()

        pointedBindings = {}
        for name, binding of this._bindings
          pointedBindings.name =
            if binding.point?
              binding.point(this._point)
            else
              Varying.ly(binding)

        finalBinding = Varying.pure(this.constructor.exec, pointedBindings.subject, pointedBindings.context,
          pointedBindings.library, pointedBindings.options)

        this._boundings = [ finalBinding.reactNow((f) => f(this._artifact, this._app)) ]

      @exec: (subject, context, library, options) -> (dom, app) ->
        view = (library?.get ? app?.getView)?(subject, util.extendNew(options ? {}, context: context ))
        dom.data('subview')?.destroy()
        dom.empty()

        if view?
          dom.append(view.artifact())
          # TODO: inform view that it has been appended.

        dom.data('subview', view)

module.exports = { Mutator, mutators, _internal: { Mutator1 } }

