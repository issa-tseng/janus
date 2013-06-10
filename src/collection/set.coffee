# **Sets** are possibly-ordered sets of objects. The base `Set` implementation
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

List = require('./list').List
util = require('../util/util')

# We derive off of List since we're essentially a list with additional rules
# evaluated at add-time, plus a possible ordering semantic
class Set extends List

  has: (elem) -> this.list.indexOf(elem) >= 0

  add: (elems) ->

    # Normalize the argument to an array, then add each elem if possible.
    elems = [ elems ] unless util.isArray(elems)

    for elem in elems
      # bail if we already have one.
      continue if this.has(elem)

      # we're all good; add and emit.
      this.list.push(elem)
      this.emit('added', elem)
      elem.emit?('addedTo', this)

      # if the item is ever destroyed, automatically remove it from our
      # collection.
      this.listenTo(elem, 'destroying', => this.remove(elem)) if elem instanceof Base

util.extend(module.exports,
  Set: Set
)

