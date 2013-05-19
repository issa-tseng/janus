util = require('../util/util')
Base = require('../core/base').Base
{ Monitor, ComboMonitor } = require('../core/monitor')


class Binder
  constructor: (@dom, @parent = null) ->
    this._children = {}
    this._mutators = {}
    this._parentMutators = []


  find: (selector) ->
    this._children[selector] ?= new Binder(this.dom.find(selector))


  classed: (className) -> this._attachMutator(ClassMutator, [ className ])
  attr: (attrName) -> this._attachMutator(AttrMutator, [ attrName ])
  css: (cssAttr) -> this._attachMutator(CssMutator, [ cssAttr ])

  text: -> this._attachMutator(TextMutator)
  html: -> this._attachMutator(HtmlMutator)

  render: (library, context) -> this._attachMutator(RenderMutator, [ library, context ])
  renderWith: (klass) -> this._attachMutator(RenderWithMutator, [ klass ])

  apply: (f) -> this._attachMutator(ApplyMutator, [ f ])

  from: (dataObj, dataKey) -> this.text().from(dataObj, dataKey)
  fromMonitor: (func) -> this.text().fromMonitor(func)


  end: -> this.parent

  data: (primary, data) ->
    child.data(primary, data) for child in this._children
    mutator.data(primary, data) for _, mutator of this._mutators
    mutator.data(primary, data) for mutator of this._parentMutators
    null


  _attachMutator: (klass, param) ->
    existingMutator = this._mutation[klass.name]
    this._parentMutators.push(existingMutator) if existingMutator?
    this._mutators[klass.name] = new klass(this.dom, existingMutator, param)


class Mutator extends Base
  constructor: (@dom, @parent = null, @params) ->
    super()

    this._data = []
    this._listeners = []
    this._fallback = this._transform = this._value = null

    this._parent?._isParent = true

    this._namedParams?(this.params)

  from: (dataObj, dataKey) ->
    if dataKey?
      this._data.push( type: 'data', obj: dataObj, key: dataKey )
    else
      this._data.push( type: 'primary', key: dataKey )

    this

  fromMonitor: (monitorGenerator) ->
    this._data.push( type: 'customMonitor', func: monitorGenerator )

  and: this.prototype.from

  andLast: ->
    this._data.push( type: 'parent' )
    this

  transform: (transform) ->
    this._transform = transform
    this

  fallback: (fallback) ->
    this._fallback = fallback
    this


  data: (primary, data) ->
    listener.destroy() for listener in this._listeners
    this._listeners =
      for { type, obj, key, func } in this._data
        if type is 'data'
          util.deepGet(data, obj)?.value(key)
        else if type is 'primary'
          primary.value(key)
        else if type is 'parent'
          this.parent.data(primary, data)
          monitor = new Monitor(this.parent.calculate())
          this.parent.on('changed', (v) -> monitor.setValue(v))
          monitor
        else if type is 'customMonitor'
          func(primary, data)

    this._value = new ComboMonitor(this._listeners, this._transform)
    this._value.destroyWith(this)
    this._value.on('changed', => this.apply())

    this

  calculate: -> this._value?.value ? this._fallback
  apply: -> this._apply(this.calculate()) unless this._isParent

  _apply: ->

class ClassMutator
  _namedParams: ([ @className ]) ->
  _apply: (bool) -> this.dom.toggleClass(this.className, bool ? false)

class AttrMutator
  _namedParams: ([ @attr ]) ->
  _apply: (value) -> this.dom.attr(this.attr, value)

class CssMutator
  _namedParams: ([ @cssAttr ]) ->
  _apply: (value) -> this.dom.css(this.cssAttr, value) # todo: maybe prefix

class TextMutator
  _apply: (text) -> this.dom.text(text)

class HtmlMutator
  _apply: (html) -> this.dom.html(html)

class RenderMutator
  _namedParams: ([ @library, @context, @options ]) ->
  _apply: (model) ->
    this.dom.empty()
      .append(this.library.get(model, context: this.context, constructorOpts: this.options).artifact())

class RenderWithMutator
  _namedParams: ([ @klass ]) ->
  _apply: (model) -> this.dom.empty().append(new this.klass(model, this.options))

class ApplyMutator
  _namedParams: ([ @f ]) ->
  _apply: (value) -> this.f(this.dom, value)

util.extend(module.exports,
  Binder: Binder
  Mutator: Mutator

  mutators:
    ClassMutator: ClassMutator
    AttrMutator: AttrMutator
    CssMutator: CssMutator
    TextMutator: TextMutator
    HtmlMutator: HtmlMutator
    RenderMutator: RenderMutator
    RenderWithMutator: RenderWithMutator
    ApplyMutator: ApplyMutator
)


