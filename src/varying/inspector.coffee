{ Model, attribute, bind, List, from, Varying } = require('janus')
{ fix, uniqueId } = require('janus').util


class WrappedVarying extends Model.build(
    attribute('observations', class extends attribute.List
      default: -> new List()
    )

    attribute('reactions', class extends attribute.List
      default: -> new List()
    )

    bind('derived', from('mapped').and('flattened').all.map((m, f) -> m or f))
    bind('value', from('_value').map((x) -> if x?.isNothing is true then null else x))

    bind('active_reactions', from('reactions').map((rxns) -> rxns.filter((rxn) -> rxn.watch('active'))))
  )

  isInspector: true
  isWrappedVarying: true

  constructor: (@varying) ->
    super({
      id: uniqueId()
      target: this.varying
      title: this.varying.constructor.name

      flattened: this.varying._flatten is true
      mapped: this.varying._f?
      applicants: (new List(this.varying.a) if this.varying.a?)
    })

  _initialize: ->
    self = this
    varying = this.varying

    # OBSERVATION TRACKING:
    # grab the current set of observations, populate.
    observations = this.get('observations')
    addObservation = (observation) =>
      oldStop = observation.stop
      observation.stop = -> observations.remove(this); oldStop.call(this)
      observations.add(observation)
    addObservation(r) for _, r of varying._observers

    # hijack the react method:
    _react = varying._react
    varying._react = (f_, immediate) ->
      observation = _react.call(varying, f_, immediate)
      addObservation(observation)
      observation

    # REACTION TRACKING:
    # listen to all our applicants' reactions if we've got many.
    self._trackReactions(a) for a in varying.a if varying.a?

    # VALUE TRACKING:
    # grab the current value, populate.
    self.set('_value', varying._value)

    # whenever a value begins propagating, begin a reaction and track its spread.
    _propagate = varying._propagate
    varying._propagate = ->
      if (extantRxn = self.get('active_reactions').at(0))?
        # we already have a reaction chain; add to it.
        extantRxn.logChange(self, varying._value)
      else
        # create a new reaction.
        newRxn = self._startReaction(varying._value, arguments.callee.caller)

      if varying._flatten is true
        newInner = varying._inner?.parent
        if (oldInner = self.get('inner')) isnt newInner
          # we are flat and the inner varying has changed.
          self._untrackReactions(oldInner) if oldInner?

          if newInner?
            self.set('inner', newInner)
            self._trackReactions(newInner)
            newInner._wrapper.get('reactions').add(extantRxn ? newRxn)
          else
            self.unset('inner')

      self.set('_value', varying._value)
      _propagate.call(varying)
      newRxn?.set('active', false)

  # called by primitive varyings to begin recording a reaction tree from root.
  _startReaction: (newValue, caller) ->
    rxn = new Reaction(this, caller)
    this.get('reactions').add(rxn)
    rxn.logChange(this, newValue)
    rxn

  # for now, naively assume this is the only cross-WV listener to simplify tracking.
  _trackReactions: (other) ->
    other = WrappedVarying.hijack(other)
    this.listenTo(other.get('reactions'), 'added', (r) =>
      unless this.get('reactions').at(-1) is r
        this.get('reactions').add(r)
        r.addNode(this)
    )
  _untrackReactions: (other) -> this.unlistenTo(WrappedVarying.hijack(other))

  @hijack: (varying) ->
    if varying.isWrappedVarying is true then varying
    else varying._wrapper ?= new WrappedVarying(varying)


# n.b. that because of the extra data snapshotting requires, the attributes
# to applicants and inner point at SnapshottedVaryings rather than bare
# ones. This ought to be transparent to all consumers.
# TODO: why does this even derive from WV?
class SnapshottedVarying extends WrappedVarying
  constructor: (data, options) ->
    Model.prototype.constructor.call(this, data, options)

  _initialize: -> # a snapshot is inert so no tracking is necessary nor desired.


class Reaction extends Model.build(
    attribute('changes', class extends attribute.List
      default: -> new List()
    )
    attribute('active', class extends attribute.Boolean
      default: -> true
    )
  )

  isReaction: true

  constructor: (root, caller) -> super({ root, caller })

  _initialize: ->
    this.set('at', new Date())
    this.set('root', this.addNode(this.get('root')))

  getNode: (wrapped) -> this.get("tree.#{wrapped.get('id')}") if wrapped?
  watchNode: (wrapped) -> this.watch("tree.#{wrapped.get('id')}") if wrapped?

  addNode: (wrapped) ->
    if (snapshot = this.getNode(wrapped))?
      return snapshot

    snapshot = new SnapshottedVarying(wrapped.data)
    this.set("tree.#{wrapped.get('id')}", snapshot)

    maybeBuild = (v) => this.addNode(WrappedVarying.hijack(v))

    if (applicants = wrapped.get('applicants'))?
      snapshot.set('applicants', new List((maybeBuild(x) for x in applicants.list)))
    snapshot.set('inner', maybeBuild(inner)) if (inner = wrapped.get('inner'))?

    if (value = wrapped.get('value'))? and value.isVarying is true
      clone = new Varying(value._value) # TODO: this is probably too imprecise
      snapshot.set('_value', clone)

    snapshot

  logChange: (wrapped, value) ->
    snapshot = this.getNode(wrapped)

    value = new Varying(value._value) if value?.isVarying is true
    snapshot.set({ new_value: value, changed: true })
    snapshot.unset('immediate')

    this.get('changes').add(snapshot)


module.exports = {
  WrappedVarying, SnapshottedVarying, Reaction,
  registerWith: (library) -> library.register(Varying, WrappedVarying.hijack)
}

