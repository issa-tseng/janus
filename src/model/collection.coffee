# **Collections** are lists of `Models`. The base `Collection` implementation
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
Model = require('./model').Model
util = require('../util/util')

# We derive off of Model so that we have free access to attributes.
class Collection extends Model

  # Declare what type we should be accepting for inclusion in this collection.
  @memberClass: Model

  # We take in a list of `Model`s and optionally some options for the
  # Collection. Options are both for framework and implementation use.
  # Framework options:
  #
  # - `ignoreDestruction`: Defaults to `false`. By default, when a member is
  #   destroyed the list will remove that child from itself. Set to false to
  #   leave the reference.
  #
  constructor: (list = [], @options = {}) ->
    super()

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
      elem.emit('addedTo', this, idx + subidx)

      # If the item is ever destroyed, automatically remove it from our
      # collection. This behavior can be turned off with the `ignoreDestruction`
      # option.
      this.listenTo(elem, 'destroying', => this.remove(elem))

    elems

  # Remove one item from the collection. Takes either an integer index
  # indicating the position of the element to remove, or a reference to the
  # element itself.
  #
  # **Returns** the removed member.
  remove: (which) ->

    # Normalize the argument to an integer index; bail if we got something
    # bizarre.
    which = this.list.indexOf(which) if which instanceof this.memberClass
    return false unless util.isNumber(which) and util >= 0

    # Actually remove the element.
    removed = this.list.splice(which, 1)[0]

    # Event on self and element.
    this.emit('removed', item, which)
    removed.emit('removedFrom', this, item, which)

    removed

  # Removes all elements from a collection.
  #
  # **Returns** the removed elements.
  removeAll: ->
    for elem, idx in this.list
      this.emit('removed', elem, idx)
      elem.emit('removedFrom', this, idx)

    oldList = this.list
    this.list = []

    oldList

  # Get an element from this collection by index.
  at: (idx) -> this.list[idx]

  # Set an index of this collection to the given member.
  #
  # This is internally modelled as if the previous item at the index was removed
  # and the new one was added in succession, but without the later members of
  # the collection slipping around.
  #
  # **Returns** the replaced element, if any.
  put: (idx, elem) ->

    # Removal of old element.
    removed = this.list[idx]
    if removed?
      this.emit('removed', removed, idx) 
      removed.emit('removedFrom', this, idx)

    # Adding the new element.
    this.list[idx] = elem
    this.emit('added', elem, idx)
    elem.emit('addedTo', this, idx)

    removed

util.extend(module.exports,
  Collection: Collection
)

