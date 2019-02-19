{ Model, attribute, bind, List, from, Varying } = require('janus')
{ fix, uniqueId } = require('janus').util


################################################################################
# SHIMS:
# WrappedVarying will hijack its inspection target and override many of its
# methods in order to actually do its job. in general, to correctly track reactions
# as they occur, there are two operations we have to be able to spot:

# 1 value reification of inert derived varyings by way of initial #react. we spot
#   these by tapping into _react.
reactShim = (f_, immediate) ->
  wrapper = this._wrapper

  # if this is the first reaction, we first need to get the/create a tracking
  # instance and push it rootwards.
  initialCompute = (this._refCount is 0) and (this._recompute?)
  if initialCompute
    rxn = wrapper.get_('active_reactions').at_(0)
    hadExtant = rxn?
    if !hadExtant
      rxn = new Reaction(wrapper, '(internal)')
      wrapper.reactions.add(rxn)

    # push the reaction one step rootwards.
    a._wrapper.reactions.add(rxn) for a in this.a if this.a?

  # do the normal work.
  observation = Object.getPrototypeOf(this)._react.call(this, f_, immediate)
  this._wrapper._addObservation(observation)

  # now do some more shimwork:
  if initialCompute
    handleInner(wrapper, this, rxn)
    wrapper.set('_value', this._value)
    rxn.logChange(wrapper, this._value)
    rxn.set('active', false) unless hadExtant
  observation

# 2 change propagation toward the leaves by way of #set on some root static Varying,
#   which we do by tapping into _propagate.
propagateShim = ->
  wrapper = this._wrapper
  # log to the existing reaction or create a new one (which logs for us).
  if (extantRxn = wrapper.get_('active_reactions').at_(0))?
    extantRxn.logChange(wrapper, this._value)
  else
    newRxn = new Reaction(wrapper, arguments.callee.caller)
    wrapper.reactions.add(newRxn)
    newRxn.logChange(wrapper, this._value)

  handleInner(wrapper, this, extantRxn ? newRxn)
  if this._value?
    wrapper.set('_value', this._value)
  else
    wrapper.unset('_value')
  Object.getPrototypeOf(this)._propagate.call(this)
  newRxn?.set('active', false)
  return

# this helper digests possible new inners and does the needful.
handleInner = (wrapper, varying, rxn) ->
  return unless varying._flatten is true
  newInner = varying._inner?.parent
  if (oldInner = wrapper.get_('inner')) isnt newInner
    # we are flat and the inner varying has changed.
    wrapper._untrackReactions(oldInner) if oldInner?
    if newInner?
      wrapper.set('inner', newInner)
      wrapper._trackReactions(newInner)
      newInner._wrapper.reactions.add(rxn)
      rxn.logInner(wrapper, WrappedVarying.hijack(newInner))
    else
      wrapper.unset('inner')
  return


################################################################################
# INSPECTOR CLASS:

class WrappedVarying extends Model.build(
    attribute('observations', class extends attribute.List
      default: -> new List()
    )

    attribute('reactions', class extends attribute.List
      default: -> new List()
    )

    bind('derived', from('mapped').and('flattened').all.map((m, f) -> m or f))
    bind('value', from('_value').map((x) -> if x?.isNothing is true then null else x))

    bind('active_reactions', from('reactions').map((rxns) -> rxns.filter((rxn) -> rxn.get('active'))))
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
      reducing: this.varying.a? and this.varying.a.length > 1
      applicants: (new List(this.varying.a) if this.varying.a?)
    })

  _initialize: ->
    # drop some vars to direct/local access for perf.
    this.observations = this.get_('observations')
    this.applicants = this.get_('applicants')
    this.reactions = this.get_('reactions')
    varying = this.varying

    # ABSORB EXTANT STATE:
    # grab the current value and extant observations, populate.
    this.set('_value', varying._value)
    this._addObservation(r) for _, r of varying._observers

    # BUILD TREE:
    # track all our parents' reactions, which also hijacks the whole tree.
    this._trackReactions(a) for a in varying.a if varying.a?

    # HIJACK METHODS:
    varying._react = reactShim
    varying._propagate = propagateShim

  _addObservation: (observation) ->
    oldStop = observation.stop
    observation.stop = => this.observations.remove(this); oldStop.call(observation)
    this.observations.add(observation)
    return

  # for now, naively assume this is the only cross-WV listener to simplify tracking.
  _trackReactions: (other) ->
    other = WrappedVarying.hijack(other)
    this.listenTo(other.get_('reactions'), 'added', (r) =>
      unless this.get_('reactions').at_(-1) is r
        this.get_('reactions').add(r)
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
    this.varying = data.target

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
    this.set('root', this.addNode(this.get_('root')))

  getNode: (wrapped) -> this.get_("tree.#{wrapped.get_('id')}") if wrapped?
  watchNode: (wrapped) -> this.watch("tree.#{wrapped.get_('id')}") if wrapped?

  addNode: (wrapped) ->
    if (snapshot = this.getNode(wrapped))?
      return snapshot

    snapshot = new SnapshottedVarying(wrapped.data)
    this.set("tree.#{wrapped.get_('id')}", snapshot)

    maybeBuild = (v) => this.addNode(WrappedVarying.hijack(v))

    if (applicants = wrapped.get_('applicants'))?
      snapshot.set('applicants', new List((maybeBuild(x) for x in applicants.list)))
    snapshot.set('inner', maybeBuild(inner)) if (inner = wrapped.get_('inner'))?

    if (value = wrapped.get_('value'))? and value.isVarying is true
      clone = new Varying(value._value) # TODO: this is probably too imprecise
      snapshot.set('_value', clone)

    snapshot

  logChange: (wrapped, value) ->
    snapshot = this.getNode(wrapped)

    value = new Varying(value._value) if value?.isVarying is true
    snapshot.set({ new_value: value, changed: true })
    snapshot.unset('immediate')

    this.get_('changes').add(snapshot)
    return

  logInner: (wrapped, inner) ->
    snapshot = this.getNode(wrapped)
    snapshot.set('new_inner', inner)
    return


module.exports = {
  WrappedVarying, SnapshottedVarying, Reaction,
  registerWith: (library) -> library.register(Varying, WrappedVarying.hijack)
}

