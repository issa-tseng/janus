util = require('../util/util')
Base = require('../core/base').Base
{ Varying, MultiVarying } = require('../core/varying')
types = require('./types')
reference = require('../model/reference')


class Binder extends Base
  constructor: (@dom, @options = {}) ->
    super()

    this._children = {}
    this._mutatorIndex = {}
    this._mutators = []

  find: (selector) -> this._children[selector] ?= new Binder(this.dom.find(selector), util.extendNew(this.options, { parent: this }))


  classed: (className) -> this._attachMutator(ClassMutator, [ className ])
  classGroup: (classPrefix) -> this._attachMutator(ClassGroupMutator, [ classPrefix ])

  attr: (attrName) -> this._attachMutator(AttrMutator, [ attrName ])
  css: (cssAttr) -> this._attachMutator(CssMutator, [ cssAttr ])

  text: -> this._attachMutator(TextMutator)
  html: -> this._attachMutator(HtmlMutator)

  render: (app, options) -> this._attachMutator(RenderMutator, [ app, options ])


  apply: (f) -> this._attachMutator(ApplyMutator, [ f ])


  from: (path...) -> this.text().from(path...)
  fromVarying: (func) -> this.text().fromVarying(func)


  end: -> this.options.parent

  data: (primary, aux, shouldRender) ->
    child.data(primary, aux, shouldRender) for _, child of this._children
    mutator.data(primary, aux, shouldRender) for mutator in this._mutators
    null


  _attachMutator: (klass, param) ->
    identity = klass.identity(param)
    existingMutator = (this._mutatorIndex[klass.name] ?= {})[identity]

    mutator = new klass(this.dom, this, param, existingMutator)
    mutator.destroyWith(this)
    this._mutatorIndex[klass.name][identity] = mutator
    this._mutators.push(mutator)
    mutator


class Mutator extends Base
  constructor: (@dom, @parentBinder, @params, @parentMutator) ->
    super()

    this._data = []
    this._listeners = []
    this._fallback = this._flatMap = this._value = null

    this._parentMutator?._isParent = true

    this._namedParams?(this.params)
    this._initialize?()

  from: (path...) ->
    this._data.push((primary) => this._from(primary, path))
    this

  fromSelf: ->
    this._data.push((primary) -> new Varying(primary))
    this

  fromAux: (key, path...) ->
    if path? and path.length > 0
      this._data.push((_, aux) => this._from(util.deepGet(aux, key), path))
    else
      this._data.push((_, aux) -> new Varying(util.deepGet(aux, key)))
    this

  fromAttribute: (key) ->
    this._data.push((primary) -> new Varying(primary.attribute(key)))
    this

  _from: (obj, path) ->
    results = []

    next = (idx) => (result) =>
      results[idx] = result

      if result instanceof reference.RequestResolver
        resolved = result.resolve(this.parentBinder.options.app)
        next(0)(obj) if resolved?
      else if result instanceof reference.ModelResolver
        resolved = result.resolve(results[idx - 1])
        next(0)(obj) if resolved?
      else if idx < path.length
        debugger if result? and !result.watch?
        result?.watch(path[idx]).map(next(idx + 1))
      else
        result

    next(0)(obj)

  fromVarying: (varyingGenerator) ->
    this._data.push((primary, aux) -> varyingGenerator(primary, aux))
    this

  and: this.prototype.from
  andSelf: this.prototype.fromSelf
  andAux: this.prototype.fromAux
  andAttribute: this.prototype.fromAttribute
  andVarying: this.prototype.fromVarying

  andLast: ->
    this._data.push =>
      this.parentMutator.data(primary, aux)
      this.parentMutator._varying

    this

  flatMap: (f) ->
    this._flatMap = f
    this

  fallback: (fallback) ->
    this._fallback = fallback
    this


  data: (primary, aux, shouldRender) ->
    listener.destroy() for listener in this._listeners
    this._listeners = (datum(primary, aux) for datum in this._data)

    process = (values...) =>
      if this._flatMap?
        this._flatMap(values...)
      else if values.length is 1
        values[0]
      else
        values

    this._varying = new MultiVarying(this._listeners, process)
    this._varying.destroyWith(this)
    this._varying.on('changed', => this.apply())

    this.apply(shouldRender)
    shouldRender = true # after one cycle, we should always render what we find

    this

  calculate: -> this._varying?.value ? this._fallback
  apply: (shouldRender = true) ->
    this._apply(this.calculate()) if this._isParent isnt true and shouldRender is true

  end: -> this.parentBinder

  @identity: -> util.uniqueId()

  _apply: ->

class ClassMutator extends Mutator
  @identity: ([ className ]) -> className
  _namedParams: ([ @className ]) ->
  _apply: (bool) -> this.dom.toggleClass(this.className, bool ? false)

class ClassGroupMutator extends Mutator
  @identity: ([ classPrefix ]) -> classPrefix
  _namedParams: ([ @classPrefix ]) ->
  _apply: (value) ->
    existingClasses = this.dom.attr('class')?.split(' ')
    if existingClasses?
      this.dom.removeClass(className) for className in existingClasses when className.indexOf(this.classPrefix) is 0
    this.dom.addClass("#{this.classPrefix}#{value}") if value? and util.isString(value)

class AttrMutator extends Mutator
  @identity: ([ attr ]) -> attr
  _namedParams: ([ @attr ]) ->
  _apply: (value) -> this.dom.attr(this.attr, if util.isPrimitive(value) then value else '')

class CssMutator extends Mutator
  @identity: ([ cssAttr ]) -> cssAttr
  _namedParams: ([ @cssAttr ]) ->
  _apply: (value) -> this.dom.css(this.cssAttr, if util.isPrimitive(value) then value else '') # todo: maybe prefix

class TextMutator extends Mutator
  @identity: -> 'text'
  _apply: (text) -> this.dom.text(if util.isPrimitive(text) then text.toString() else '')

class HtmlMutator extends Mutator
  @identity: -> 'html'
  _apply: (html) -> this.dom.html(if util.isPrimitive(html) then html.tString() else '')

class RenderMutator extends Mutator
  _namedParams: ([ @app, @options ]) ->
  apply: (shouldRender = true) ->
    this._render(this._viewFromResult(this.calculate()), shouldRender) unless this._isParent

  _viewFromResult: (result) ->
    # do this up front so that we don't confuse our codepaths.
    lastKlass = this._lastKlass
    delete this._lastKlass

    if !result?
      null
    else if result instanceof types.WithOptions
      this.app.getView(result.model, result.options)
    else if result instanceof types.WithView
      result.view
    else if result instanceof types.WithAux and result.primary?
      constructorOpts = util.extendNew(this.options.constructorOpts, { aux: result.aux })
      this.app.getView(result.primary, util.extendNew(this.options, { constructorOpts: constructorOpts }))
    else
      this.app.getView(result, this.options)

  _render: (view, shouldRender) ->
    this._clear()
    this._lastView = view

    if view?
      view.destroyWith(this)

      if shouldRender is true
        this.dom.empty()

        this.dom.append(view.artifact())
        view.emit('appended') # TODO: is this the best RPC here?
      else
        view.bind(this.dom.contents())

  _clear: -> this._lastView.destroy() if this._lastView?

class ApplyMutator extends Mutator
  _namedParams: ([ @f ]) ->
  _apply: (value) -> this.f(this.dom, value)

util.extend(module.exports,
  Binder: Binder
  Mutator: Mutator

  mutators:
    ClassMutator: ClassMutator
    ClassGroupMutator: ClassGroupMutator
    AttrMutator: AttrMutator
    CssMutator: CssMutator
    TextMutator: TextMutator
    HtmlMutator: HtmlMutator
    RenderMutator: RenderMutator
    ApplyMutator: ApplyMutator
)


