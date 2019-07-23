# **Views** are very general abstractions that are expected to generate one
# artifact (commonly but not always a DOM object), bind events against it, and
# be able to rebind to them when asked to.
#
# It's recommended but optional that one use the templating engine Janus
# supplies with its Views.

Base = require('../core/base').Base
{ Varying } = require('../core/varying')
{ dynamic, get, subject, attribute, vm, varying, app, self } = require('../core/types').from
{ match } = require('../core/case')
{ List } = require('../collection/list')
navigation = require('./navigation')
{ parent_, closest_, into_, intoAll_, parent, closest, into, intoAll } = navigation
{ isFunction, isString } = require('../util/util')


# Base gives us event listening things
class View extends Base

  # The `View` takes first and foremost a `subject`, which is the object it aims
  # to create a view for. It also takes an `options` hash, which has no
  # predefined behavior.
  constructor: (@subject, @options = {}) ->
    super()

    # If we have a reference to a ViewModel intermediary, instantiate and store it.
    if this.constructor.viewModelClass?
      this.viewModel = this.vm = new this.constructor.viewModelClass({
        subject: this.subject
        view: this
        options: this.options
      }, { app: this.options.app })
      this.viewModel.destroyWith(this)

    this._initialize?()

  # Returns the artifact this View is managing. If it has not yet created one,
  # the View will delegate to `_render()` to create one. That method has no
  # default implementation.
  artifact: -> this._artifact ?= this._render()
  _render: -> # implement me!

  # Standard point implementation that all subclasses can typically use unaltered.
  pointer: -> this.pointer$ ?= match(
    dynamic (x) =>
      if isString(x) and this.subject.get?
        this.subject.get(x)
      else if isFunction(x)
        Varying.of(x(this.subject))
      else
        Varying.of(x)
    get (x) => this.subject.get(x)
    subject (x) => if x? then this.subject.get(x) else new Varying(this.subject)
    attribute (x) => new Varying(this.subject.attribute(x))
    vm (x) => if x? then this.viewModel?.get(x) else new Varying(this.viewModel)
    varying (x) => if isFunction(x) then Varying.of(x(this.subject)) else Varying.of(x)
    app (x) =>
      if x? then this.options.app.get(x)
      else new Varying(this.options.app)
    self (x) => if isFunction(x) then Varying.of(x(this)) else Varying.of(this)
  )

  # navigation plumb-throughs
  parent: (selector) -> parent(selector, this)
  parent_: (selector) -> parent_(selector, this)
  closest: (selector) -> closest(selector, this)
  closest_: (selector) -> closest_(selector, this)
  into: (selector) -> into(selector, this)
  into_: (selector) -> into_(selector, this)
  intoAll: (selector) -> intoAll(selector, this)
  intoAll_: (selector) -> intoAll_(selector, this)
  @navigation: navigation # in case anybody would rather use a functional syntax.


module.exports = { View }

