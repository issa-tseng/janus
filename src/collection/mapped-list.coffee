{ List, DerivedList } = require('./list')
Varying = require('../core/varying').Varying
util = require('../util/util')

class MappedList extends DerivedList
  constructor: (@parent, @mapper, @options = {}) ->
    super()

    # add initial items then keep track of membership changes.
    this._add(elem) for elem in this.parent.list
    this.parent.on('added', (elem, idx) => this._add(elem, idx))
    this.parent.on('removed', (_, idx) => this._removeAt(idx))

  _add: (elem, idx) -> super(this.mapper(elem), idx)

class FlatMappedList extends DerivedList
  constructor: (@parent, @mapper, @options = {}) ->
    super()

    # keep track of our maps so that we can appropriately discard later.
    this._bindings = new List()

    # add initial items then keep track of membership changes.
    this._add(elem, idx) for elem, idx in this.parent.list
    this.parent.on('added', (elem, idx) => this._add(elem, idx))
    this.parent.on('removed', (_, idx) => this._removeAt(idx))

  _add: (elem, idx) ->
    wrapped = new Varying(elem)

    initial = null
    mapping = wrapped.flatMap(this.mapper)
    binding = mapping.reactNow((newValue) =>
      initial ?= newValue # perf: saves us one mapping.get()
      bidx = this._bindings.list.indexOf(binding)
      this._put(newValue, bidx) if bidx >= 0
    )

    this._bindings.add(binding, idx)
    super(initial, idx)

  _removeAt: (idx) ->
    this._bindings.removeAt(idx).stop()
    super(idx)


util.extend(module.exports,
  FlatMappedList: FlatMappedList
  MappedList: MappedList
)

