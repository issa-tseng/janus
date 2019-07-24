{ List, DerivedList } = require('../list')
Varying = require('../../core/varying').Varying


class MappedList extends DerivedList
  constructor: (@parent, @mapper, @options = {}) ->
    super()
    this.destroyWith(this.parent)

    # add initial items then keep track of membership changes.
    this._add(elem) for elem in this.parent.list
    this.listenTo(this.parent, 'added', (elem, idx) => this._add(elem, idx))
    this.listenTo(this.parent, 'moved', (_, idx, oldIdx) => this._moveAt(oldIdx, idx))
    this.listenTo(this.parent, 'removed', (_, idx) => this._removeAt(idx))

  _add: (elem, idx) -> super(this.mapper(elem), idx); return

class FlatMappedList extends DerivedList
  constructor: (@parent, @mapper, @options = {}) ->
    super()

    # keep track of our maps so that we can appropriately discard later.
    this._bindings = new List()

    # add initial items then keep track of membership changes.
    this._add(elem, idx) for elem, idx in this.parent.list
    this.listenTo(this.parent, 'added', (elem, idx) => this._add(elem, idx))
    this.listenTo(this.parent, 'removed', (_, idx) => this._removeAt(idx))
    this.listenTo(this.parent, 'moved', (_, idx, oldIdx) => this._moveAt(oldIdx, idx))

  _add: (elem, idx) ->
    wrapped = new Varying(elem)

    initial = null
    mapping = wrapped.flatMap(this.mapper)
    binding = this.reactTo(mapping, (newValue) =>
      initial ?= newValue # perf: saves us one mapping.get()
      bidx = this._bindings.list.indexOf(binding)
      this._set(bidx, newValue ? null) if bidx >= 0 # null to get around currying :( :(
    )

    this._bindings.add(binding, idx)
    super(initial, idx)
    return

  _removeAt: (idx) ->
    this._bindings.removeAt(idx).stop()
    super(idx)
    return

  _moveAt: (oldIdx, idx) ->
    this._bindings.moveAt(oldIdx, idx)
    super(oldIdx, idx)
    return


module.exports = { MappedList, FlatMappedList }

