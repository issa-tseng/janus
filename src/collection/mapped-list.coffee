{ List, DerivedList } = require('./list')
Varying = require('../core/varying').Varying
util = require('../util/util')

# A read-only view into a proper `List` that maps all elements to new ones. The
# mapping can be based on a `Varying`, which means that the mapping can change
# over time independently of list changes.
class MappedList extends DerivedList
  constructor: (@parent, @mapper, @options = {}) ->
    super()

    # keep track of our maps so that we can appropriately discard later.
    this._mappers = new List()

    # add initial items then keep track of membership changes.
    this._add(elem) for elem in this.parent.list
    this.parent.on('added', (elem, idx) => this._add(elem, idx))
    this.parent.on('removed', (_, idx) => this._removeAt(idx))

  _add: (elem, idx) ->
    wrapped = Varying.ly(elem)

    mapped = wrapped.map(this.mapper)
    mapped.destroyWith(wrapped)
    this._mappers.add(mapped, idx)

    mapped.on('changed', (newValue) => this._put(newValue, this._mappers.list.indexOf(mapped)))
    super(mapped.value, idx)

  _removeAt: (idx) ->
    this._mappers.removeAt(idx)?.destroy()
    super(idx)


util.extend(module.exports,
  MappedList: MappedList
)

