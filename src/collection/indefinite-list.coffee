# An `IndefiniteList` is loosely a sort of a composable lens which extracts
# into a list. But the functional description of it is too vague to represent
# it, so we'll just call it an `IndefiniteList` and move on with our lives.
#
# The idea is that an `IndefiniteList` is a list which is seeded with a step
# function. That step function's obligation is to return the next step (either
# one or more new members of the list, an `Indefinite` end, or a `Termination`),
# along with a new step function.
#
# A meaningful application of this abstraction is to express a workflow wherein
# the steps to be involved in the future are dependent on the input at each
# step. Because we allow timevarying step function results via a `Varying`
# return, this allows us to declaratively rebind future steps when existing
# state is changed.

Base = require('../core/base').Base
OrderedCollection = require('./types').OrderedCollection
Varying = require('../core/varying').Varying
util = require('../util/util')

# Some result classes to typematch against and extract result data.
class StepResult
class One extends StepResult
  constructor: (@elem, @step) ->
class Many extends StepResult
  constructor: (@elems, @step) ->
class Indefinite extends StepResult
class Termination extends StepResult

# We derive off of Model so that we have free access to attributes.
class IndefiniteList extends OrderedCollection
  constructor: (step, @options = {}) ->
    super()

    # set up our list.
    this.list = []

    # run our first step.
    this._step(step, 0)

  # Get an element from this collection by index.
  at: (idx) -> this.list[idx]

  _step: (step, idx) ->
    result = step()

    # set up a handler to actual deal with the step result
    process = (result) =>
      this._truncate(idx)

      if result instanceof One
        this.list.push(result.elem)

        this.emit('added', result.elem, idx)
        result.elem.emit?('addedTo', this, idx)

        this._step(result.step, idx + 1)

      else if result instanceof Many
        this.list = this.list.concat(result.elems)

        for elem, subidx in result.elems
          this.emit('added', elem, idx + subidx)
          elem.emit?('addedTo', this, idx + subidx)

        this._step(result.step, idx + result.elems.length)

      else if result instanceof Indefinite
        this.set('completion', Indefinite)

      else if result instanceof Termination
        this.set('completion', Termination)

    if result instanceof Varying
      result.on('changed', (newResult) -> process(newResult))
      process(result.value)
    else
      process(result)

  _truncate: (idx) ->
    removed = this.list.splice(idx, this.list.length - idx)

    for elem, subidx in removed
      this.emit('removed', elem, idx + subidx)
      elem.emit?('removedFrom', this, idx + subidx)

    null

  @One: (elem, step) -> new One(elem, step)
  @Many: (elems, step) -> new Many(elems, step)
  @Indefinite: new Indefinite
  @Termination: new Termination


util.extend(module.exports,
  IndefiniteList: IndefiniteList

  result:
    StepResult: StepResult
    One: One
    Many: Many
    Indefinite: Indefinite
    Termination: Termination
)

