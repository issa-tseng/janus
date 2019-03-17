{ List } = require('../collection/list')
{ identity } = require('../util/util')

match = (selector, view) ->
  if undefined is selector then true
  else if view is selector then true
  else if selector[Symbol.hasInstance]?
    if view instanceof selector then true
    else if view?.subject instanceof selector then true

# TODO: all this would i guess be more efficient with transducers?
# but we're not going to do all that yet.
# TODO: also these flatMaps/flattens are sort of painful.

into = (selector) -> (selection, primitive) ->
  if primitive is true
    results = []
    for selected in selection
      for binding in selected._bindings when binding.view?
        view = binding.view.get()
        results.push(view) if view? and match(selector, view) is true
    results
  else
    selection.map((selected) ->
      bindings = new List(binding.view for binding in selected._bindings when binding.view?)
      bindings.flatMap(identity).filter((view) -> view? and match(selector, view))
    ).flatten()

parentQ = (selector) -> (selection, primitive) ->
  if primitive is true
    results = []
    for selected in selection
      parent = selected.options.parent
      if parent? and match(selector, parent) is true and (results.indexOf(parent) is -1)
        results.push(parent)
    results
  else
    selection
      .map((selected) -> selected.options.parent)
      .filter((parent) -> parent? and match(selector, parent))
      .uniq()

closest = (selector) -> (selection, primitive) ->
  if primitive is true
    results = []
    for selected in selection
      parent = selected.options.parent
      while parent?
        if match(selector, parent) is true
          results.push(parent) if results.indexOf(parent) is -1
          parent = null
        else
          parent = parent.options.parent
    results
  else
    selection # here we rely on the assumption that parents don't change.
      .map((view) ->
        parent = view.options.parent
        while parent?
          return parent if match(selector, parent) is true
          parent = parent.options.parent
        return
      )
      .filter((x) -> x?)
      .uniq()

# we have both public get/get_ as well as private _get since we'd like eg
# .first().get() to just yield one item rather than a sequence, but we'd also like
# .first().parent() etc to work, which makes it a query reducer that still
# returns a sequence. so _get always returns a sequence.
class Navigator
  constructor: (@precedent, @op) ->
  
  ########################################
  # navigate

  parent: (selector) -> new Navigator(this, parentQ(selector))
  into: (selector) -> new Navigator(this, into(selector))
  closest: (selector) -> new Navigator(this, closest(selector))

  first: -> new NavigateOne(this, 0)
  last: -> new NavigateOne(this, -1)

  ########################################
  # reify

  get_: -> this.op(this.precedent._get(true), true)
  get: -> this.op(this.precedent._get(false), false)
  _get: (primitive) -> this.op(this.precedent._get(primitive), primitive)

class NavigateOne extends Navigator
  constructor: (@precedent, @idx) ->
  get_: ->
    selection = this.precedent._get(true)
    idx = if this.idx < 0 then selection.length + this.idx else this.idx
    selection[idx]
  get: -> this.precedent._get(false).at(this.idx)
  _get: (primitive) ->
    if primitive is true then [ this.get_() ]
    else (new List([ null ])).flatMap(=> this.get())

class NavigatorRoot extends Navigator
  constructor: (@selection) ->
  get_: -> [ this.selection ]
  get: -> new List(this.selection)
  _get: (primitive) -> if primitive is true then this.get_() else this.get()


module.exports = { Navigator, NavigatorRoot, match }

