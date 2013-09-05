# **Lists** are ordered lists of objects. The base `List` implementation
# is pretty simple; one can add and remove elements to and from it.
#
# **Events**:
#
# - `added`: `(item, idx)` the item that was added and its position.
# - `removed`: `(item, idx)` the item that was removed and its position.
#
# **Member Events**:
#
# - `addedTo`: `(collection, idx)` this collection and the member's position.
# - `removedFrom`: `(collection, idx)` this collection and the member's
#   position.

Base = require('../core/base').Base
Varying = require('../core/varying').Varying
OrderedCollection = require('./types').OrderedCollection
Model = require('../model/model').Model
Reference = require('../model/reference').Reference
util = require('../util/util')

# We derive off of Model so that we have free access to attributes.
class List extends OrderedCollection

  # We take in a list of `Model`s and optionally some options for the
  # List. Options are both for framework and implementation use.
  # Framework options:
  #
  # - `ignoreDestruction`: Defaults to `false`. By default, when a member is
  #   destroyed the list will remove that child from itself. Set to false to
  #   leave the reference.
  #
  constructor: (list = [], @options = {}) ->
    super({}, @options)

    # Init our list, and add the items to it.
    this.list = []
    this.add(list)

    # Allow setup tasks without overriding+passing along constructor args.
    this._initialize?()

  # Add one or more items to this collection. Optionally takes a second `index`
  # parameter indicating what position in the list all the items should be
  # spliced in at.
  #
  # **Returns** the added items as an array.
  add: (elems, idx = this.list.length) ->

    # Normalize the argument to an array, then dump in our items.
    elems = [ elems ] unless util.isArray(elems)
    Array.prototype.splice.apply(this.list, [ idx, 0 ].concat(elems))

    for elem, subidx in elems
      # Event on ourself for each item we added
      this.emit('added', elem, idx + subidx) 

      # Event on the item for each item we added
      elem?.emit?('addedTo', this, idx + subidx)

      # If the item is ever destroyed, automatically remove it from our
      # collection. This behavior can be turned off with the `ignoreDestruction`
      # option.
      (do (elem) => this.listenTo(elem, 'destroying', => this.remove(elem))) if elem instanceof Base

    elems

  # Remove one item from the collection. Takes a reference to the element
  # to be removed.
  #
  # **Returns** the removed member.
  remove: (which) ->
    idx = this.list.indexOf(which)
    return false unless util.isNumber(idx) and idx >= 0
    this.removeAt(idx)

  # Remove one item from the collection. Takes a reference to the element
  # to be removed.
  #
  # **Returns** the removed member.
  removeAt: (idx) ->
    removed = this.list.splice(idx, 1)[0]

    # Event on self and element.
    this.emit('removed', removed, idx)
    removed?.emit?('removedFrom', this, idx)

    removed

  # Move an item to an index in the collection. This will trigger `moved`
  # events for only the shifted element. But, it will give the new and old
  # indices so that ranges can be correctly dealt with if necessary.
  move: (elem, idx) ->

    # If we don't already know about the element, bail.
    oldIdx = this.list.indexOf(elem)
    return unless oldIdx >= 0

    # Move the element, then trigger `moved` event.
    this.list.splice(oldIdx, 1)
    this.list.splice(idx, 0, elem)

    this.emit('moved', elem, idx, oldIdx)
    elem?.emit?('movedIn', this.list, idx, oldIdx)

    elem

  # Removes all elements from a collection.
  #
  # **Returns** the removed elements.
  removeAll: ->
    for elem, idx in this.list
      this.emit('removed', elem, idx)
      elem?.emit?('removedFrom', this, idx)

    oldList = this.list
    this.list = []

    oldList

  # Get an element from this collection by index.
  at: (idx) ->
    if idx >= 0
      this.list[idx]
    else
      this.list[this.list.length + idx]

  # Watch an element from this collection by index.
  watchAt: (idx) ->
    result = new Varying(this.at(idx))

    # TODO: finer-grained
    this.on('added', -> result.setValue(this.at(idx)))
    this.on('removed', -> result.setValue(this.at(idx)))

    result

  # Watch the length of this collection.
  watchLength: ->
    result = new Varying(this.list.length)

    # TODO: noop multi-changes (eg put) ?
    this.on('added', -> result.setValue(this.list.length))
    this.on('removed', -> result.setValue(this.list.length))

    result

  # Set an index of this collection to the given member.
  #
  # This is internally modelled as if the previous item at the index was removed
  # and the new one was added in succession, but without the later members of
  # the collection slipping around.
  #
  # **Returns** the replaced element, if any.
  put: (idx, elems...) ->

    # Do the actual splice. If nothing yet exists at the target, populate it
    # with null so that splice does the right thing.
    unless this.list[idx]?
      this.list[idx] = null
      delete this.list[idx]
    removed = this.list.splice(idx, elems.length, elems...)

    # Event on removals
    for elem, subidx in removed when elem?
      this.emit('removed', elem, idx + subidx)
      elem?.emit?('removedFrom', this, idx + subidx)

    # Event on additions
    for elem, subidx in elems
      this.emit('added', elem, idx + subidx)
      elem?.emit?('addedTo', this, idx + subidx)

    removed

  # Smartly resets the entire list to a new one. Does a merge of the two such
  # that adds/removes are limited.
  putAll: (list) ->
    # first remove all existing models that should no longer exist.
    oldList = this.list.slice()
    (this.remove(elem) unless list.indexOf(elem) >= 0) for elem in oldList

    # now go through each elem one at a time and add or move as necessary.
    for elem, i in list
      continue if this.list[i] is elem

      oldIdx = this.list.indexOf(elem)
      if oldIdx >= 0
        this.move(elem, i)
      else
        this.add(elem, i)

    # return the list that was set.
    list

  # A shadow list is really just a clone that has a backreference so that we
  # can determine later if it has changed. We could copy-on-write, but that
  # seems like an unpredictable behaviour to build against.
  #
  # We also shadow all Models we contain at time-of-copy.
  #
  # **Returns** a copy of this list with its parent reference set.
  shadow: ->
    newArray =
      for item in this.list
        if item instanceof Model
          item.shadow()
        else
          item

    new List(newArray, util.extendNew(this.options, { parent: this }))

  # Check if our list has changed relative to its shadow parent.
  #
  # **Returns** true if we have been modified.
  modified: (deep = true) ->
    return false unless this._parent?
    return true if this._parent.list.length isnt this.list.length

    for value, i in this.list
      parentValue = this._parent.list[i]

      if value instanceof Model
        if deep is true
          return true if value.modified()
        else
          return true if parentValue isnt value._parent
      else
        return true if parentValue isnt value

    return false

  @deserialize: (data) ->
    items =
      if this.modelClass? and this.modelClass.prototype instanceof Model
        this.modelClass.deserialize(datum) for datum in data
      else
        data.slice()

    new this(items)

  @_plainObject: (method, list) ->
    for child in list.list
      if child instanceof Reference
        child =
          if child.value instanceof Model
            child.value
          else
            child.flatValue

      if child[method]?
        child[method]()
      else
        child

class DerivedList extends List
  for method in [ 'add', 'remove', 'removeAt', 'removeAll', 'put', 'putAll', 'move' ]
    this.prototype["_#{method}"] = this.__super__[method]
    this.prototype[method] = (->)

  shadow: -> this


util.extend(module.exports,
  List: List
  DerivedList: DerivedList
)

