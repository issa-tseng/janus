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

  isWrappedVarying: true

  constructor: (@varying) ->
    super({
      id: uniqueId()
      target: this.varying
      title: this.varying.constructor.name

      flattened: this.varying._flatten is true
      mapped: this.varying._f?

      # parent is filled if this is mapped; parents if it is composed.
      parent: this.varying._parent
      parents: (new List(this.varying._applicants) if this.varying._applicants?)
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
    if (_react = varying._react)? # primitive varying
      varying._react = (f_, immediate) ->
        observation = _react.call(varying, f_, immediate)
        self.unset('parent_reaction')
        addObservation(observation)
        observation
    else # derived varying
      varying.react = (f_) ->
        observation = Varying.prototype.react.call(varying, f_)
        self.unset('parent_reaction')
        addObservation(observation)
        observation

    # REACTION TRACKING:
    # listen to our parent's reactions if we've got one.
    self._trackReactions(varying._parent) if varying._parent?

    # listen to all our parents' reactions if we've got many.
    self._trackReactions(x) for x in varying._applicants if varying._applicants?

    # VALUE TRACKING:
    # grab the current value, populate.
    self.set('_value', varying._value)

    # for primitive varyings, hijack the set method to set a current value and
    # record a Reaction.
    if (_set = varying.set)?
      varying.set = (value) ->
        rxn = self._startReaction(value, arguments.callee.caller)

        self.set('_value', value)

        _set.call(this, value)
        rxn.set('active', false)
        null

    # for derived varyings, hijack the _onValue method instead.
    if (_onValue = varying._onValue)?
      varying._onValue = (observation, value, silent) ->
        if (extantRxn = self.get('active_reactions').at(0))?
          # we already know which reaction chain to log to; do it.
          extantRxn.logChange(self, value)
        else if (extantRxn = self.unset('parent_reaction'))?
          # we were spawned mid-reaction by a parent WV; it tells us where we are by
          # setting our parent_reaction. pull it off and set it up properly.
          snapshot = extantRxn.addNode(self)
          latest = extantRxn.get('latest')
          latest.set('new_inner', snapshot) unless latest.get('inner') is snapshot
          extantRxn.logChange(self, value)
        else
          # nothing has been set, but by virtue of a new observation we are now
          # computing what was previously not. create a reaction.
          # TODO: is this always true, or are there other causes for this branch?
          # * for instance, it's debatable whether a silent=true call borne out
          #   of a .react() is worth a Reaction, as the internal code really just
          #   calls onValue out of convenience.
          newRxn = self._startReaction(value, arguments.callee.caller)

        if varying._flatten is true
          if observation is varying._parentObservation
            # we have a potentially new value at the top level; change what we are tracking.
            self._untrackReactions(oldInner) if (oldInner = self.get('inner'))?

            if value?.isVarying is true
              self.set('inner', value)
              self._trackReactions(value)
              WrappedVarying.hijack(value).set('parent_reaction', extantRxn ? newRxn)
              # the new varying will onValue as the change propagates down.
            else
              self.unset('inner')
          else
            # do things for inner value changing??
            null

        self.unset('immediate')
        self.set('_value', value)

        _onValue.call(varying, observation, value, silent)
        newRxn?.set('active', false)

    # hijack the immediate method:
    if (_immediate = varying._immediate)?
      varying._immediate = ->
        result = _immediate.call(varying)
        if result?.isVarying and varying._flatten is true
          self.set('inner', result)
          self.set('immediate', result.get()) # TODO: messy; not the actual result value instance
        else
          self.set('immediate', result)
        result

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
      unless this.get('reactions').list.indexOf(r) >= 0
        this.get('reactions').add(r)
        r.addNode(this)
    )
  _untrackReactions: (other) -> this.unlistenTo(WrappedVarying.hijack(other))

  @hijack: (varying) -> if varying.isWrappedVarying is true then varying else varying._wrapper ?= new WrappedVarying(varying)


# n.b. that because of the extra data snapshotting requires, the attributes
# to parent, parents, and inner point at SnapshottedVaryings rather than bare
# ones. This ought to be transparent to all consumers.
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
  watchNode: (wrapped) -> wrapped?.watch('id').flatMap((id) => this.watch("tree.#{id}"))

  addNode: (wrapped) ->
    if (snapshot = this.getNode(wrapped))?
      return snapshot

    snapshot = new SnapshottedVarying(wrapped.data)
    this.set("tree.#{wrapped.get('id')}", snapshot)

    maybeBuild = (v) => this.addNode(WrappedVarying.hijack(v))

    snapshot.set('parent', maybeBuild(parent)) if (parent = wrapped.get('parent'))?
    snapshot.set('parents', new List((maybeBuild(x) for x in parents.list))) if (parents = wrapped.get('parents'))?
    snapshot.set('inner', maybeBuild(inner)) if (inner = wrapped.get('inner'))?

    if (value = wrapped.get('value'))? and value.isVarying is true
      clone = new Varying(value._value)
      snapshot.set('_value', clone)

    snapshot

  logChange: (wrapped, value) ->
    snapshot = this.getNode(wrapped)
    this.set('latest', snapshot) # ehh sort of a hack

    value = new Varying(value._value) if value?.isVarying is true
    snapshot.set({ new_value: value, changed: true })
    snapshot.unset('immediate')

    this.get('changes').add(snapshot)


module.exports = {
  WrappedVarying, SnapshottedVarying, Reaction,
  registerWith: (library) -> library.register(Varying, WrappedVarying.hijack)
}

