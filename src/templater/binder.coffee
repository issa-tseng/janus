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


  find: (selector) -> this._children[selector] ?= new Binder(this.dom.find(selector), parent: this)


  classed: (className) -> this._attachMutator(ClassMutator, [ className ])
  classGroup: (classPrefix) -> this._attachMutator(ClassGroupMutator, [ classPrefix ])

  attr: (attrName) -> this._attachMutator(AttrMutator, [ attrName ])
  css: (cssAttr) -> this._attachMutator(CssMutator, [ cssAttr ])

  text: -> this._attachMutator(TextMutator)
  html: -> this._attachMutator(HtmlMutator)

  render: (app, options) -> this._attachMutator(RenderMutator, [ app, options ])
  renderWith: (klass, options) -> this._attachMutator(RenderWithMutator, [ klass, options ])


  apply: (f) -> this._attachMutator(ApplyMutator, [ f ])


  from: (path...) -> this.text().from(path...)
  fromVarying: (func) -> this.text().fromVarying(func)


  end: -> this.options.parent

  data: (primary, aux) ->
    child.data(primary, aux) for _, child of this._children
    mutator.data(primary, aux) for mutator in this._mutators
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
    this._fallback = this._transform = this._value = null

    this._parentMutator?._isParent = true

    this._namedParams?(this.params)
    this._initialize?()

  from: (path...) ->
    this._data.push((primary) => this._from(primary, path))
    this

  fromSelf: ->
    this._data.push((primary) -> new Varying( value: primary ))
    this

  fromAux: (key, path...) ->
    if path? and path.length > 0
      this._data.push((_, aux) => this._from(util.deepGet(aux, key), path))
    else
      this._data.push((_, aux) -> new Varying( value: util.deepGet(aux, key) ))
    this

  fromAttribute: (key) ->
    this._data.push((primary) -> new Varying( value: primary.attribute(key) ))
    this

  _from: (obj, path) ->
    next = (idx) => (result) =>
      if result instanceof reference.RequestReference
        result.value.resolve(this.parentBinder.options.app) if result.value instanceof reference.RequestResolver
        if path[idx]?
          result.map(next(idx))
        else
          result
      else if path[idx + 1]?
        result?.watch(path[idx], next(idx + 1))
      else
        result?.watch(path[idx])

    next(0)(obj)

  fromVarying: (varyingGenerator) ->
    this._data.push((primary, aux) -> varyingGenerator(primary, aux))
    this

  and: this.prototype.from
  andAux: this.prototype.fromAux
  andVarying: this.prototype.fromVarying

  andLast: ->
    this._data.push =>
      this.parentMutator.data(primary, aux)
      this.parentMutator._varying

    this

  transform: (transform) ->
    this._transform = transform
    this

  flatMap: this.prototype.transform

  fallback: (fallback) ->
    this._fallback = fallback
    this


  data: (primary, aux, shouldRender) ->
    listener.destroy() for listener in this._listeners
    this._listeners = (datum(primary, aux) for datum in this._data)

    process = (values...) =>
      if this._transform?
        this._transform(values...)
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
    this._apply(this.calculate()) unless this._isParent if shouldRender is true

  end: -> this.parentBinder

  @identity: -> util.uniqueId()

  _apply: ->

traverseFrom = (obj, path, transform) ->

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
  _apply: (value) -> this.dom.attr(this.attr, if util.isString(value) or util.isNumber(value) then value else '')

class CssMutator extends Mutator
  @identity: ([ cssAttr ]) -> cssAttr
  _namedParams: ([ @cssAttr ]) ->
  _apply: (value) -> this.dom.css(this.cssAttr, if util.isString(value) or util.isNumber(value) then value else '') # todo: maybe prefix

class TextMutator extends Mutator
  @identity: -> 'text'
  _apply: (text) -> this.dom.text(if util.isString(text) then text else '')

class HtmlMutator extends Mutator
  @identity: -> 'html'
  _apply: (html) -> this.dom.html(if util.isString(html) then html else '')

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
    else if result instanceof types.WithAux
      constructorOpts = util.extendNew(this.options.constructorOpts, { aux: result.aux })
      this.app.getView(result.primary, util.extendNew(this.options, { constructorOpts: constructorOpts }))
    else
      this.app.getView(result, this.options)

  _render: (view, shouldRender) ->
    this._clear()
    this._lastView = view

    this.dom.empty()

    if view?
      view.destroyWith(this)

      if shouldRender is true
        this.dom.append(view.artifact())
        view.emit('appended') # TODO: is this the best RPC here?
      else
        view.bind(this.dom.contents())

  _clear: -> this._lastView.destroy() if this._lastView?

class RenderWithMutator extends Mutator
  _namedParams: ([ @klass, @options ]) ->
  _apply: (model) -> this.dom.empty().append(new this.klass(model, this.options))

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
    RenderWithMutator: RenderWithMutator
    ApplyMutator: ApplyMutator
)


