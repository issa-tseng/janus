{ Varying, Base } = require('janus')

nothing = {}

class ManagedObservation extends Base
  constructor: (@varying) -> super()
  react: (x, y) -> this.reactTo(this.varying, x, y)
  @with: (varying) -> -> new ManagedObservation(varying)

varyingUtils = {
  ManagedObservation

  sticky: (delays = {}, v) ->
    return ((v) -> varyingUtils.sticky(delays, v)) unless v?

    Varying.managed(ManagedObservation.with(v), (mo) ->
      result = new Varying(v.get())

      value = timer = null
      update = -> timer = null; result.set(value)
      mo.react((newValue) ->
        if timer?
          value = newValue
        else if (delay = delays[value])?
          value = newValue
          timer = setTimeout(update, delay)
        else
          value = newValue
          update()
      )

      result
    )

  debounce: (cooldown, v) ->
    return ((v) -> varyingUtils.debounce(cooldown, v)) unless v?

    Varying.managed(ManagedObservation.with(v), (mo) ->
      result = new Varying(v.get())

      timer = null
      mo.react((value) ->
        clearTimeout(timer) if timer?
        timer = setTimeout((-> result.set(value)), cooldown)
      )

      result
    )

  delay: (ms, v) ->
    return ((v) -> varyingUtils.delay(ms, v)) unless v?

    Varying.managed(ManagedObservation.with(v), (mo) ->
      result = new Varying(v.get())
      mo.react((value) -> setTimeout((-> result.set(value)), ms))
      result
    )

  throttle: (delay, v) ->
    return ((v) -> varyingUtils.throttle(delay, v)) unless v?

    Varying.managed(ManagedObservation.with(v), (mo) ->
      result = new Varying(v.get())

      timer = null
      pendingValue = nothing
      mo.react(false, (value) ->
        if timer?
          pendingValue = value
        else
          result.set(value)
          timer = setTimeout((->
            timer = null
            return if pendingValue is nothing
            result.set(pendingValue)
            pendingValue = nothing
          ), delay)
      )

      result
    )

  filter: (predicate, v) ->
    return ((v) -> varyingUtils.filter(predicate, v)) unless v?

    Varying.managed(ManagedObservation.with(v), (mo) ->
      result = new Varying(undefined) # not guaranteed an initial value!
      lastObservation = null # manually manage chained varyings until we come up with something smarter.
      mo.react((value) ->
        lastObservation?.stop()
        lastObservation = Varying.of(predicate(value)).react((take) -> result.set(value) if take is true)
      )
      result
    )

  zipSequential: (v, wait = true) ->
    return ((w) -> varyingUtils.zipSequential(w, v)) if v is true or v is false

    Varying.managed(ManagedObservation.with(v), (mo) ->
      result = new Varying([]) # no initial value.
      last = (if wait is true then nothing else null)
      mo.react((value) ->
        result.set([ last, value ]) unless last is nothing
        last = value
      )
      result
    )

  # either (dom, event, initial, valueMap)
  # or (dom, event, valueMap) in which case initial is true
  fromEvent: (jq, event, x, y) ->
    initial =
      if y is undefined then true
      else x
    f = y ? x

    manager = (d_) -> manager.destroy = d_
    Varying.managed((-> manager), (destroyer) ->
      result = new Varying()

      f_ = (event) -> result.set(f.call(this, event))
      f_() if initial is true
      jq.on(event, f_)
      destroyer(-> jq.off(event, f_))

      result
    )

  fromEvents: (jq, initial, eventMap) ->
    manager = (d_) -> manager.destroy = d_
    Varying.managed((-> manager), (destroyer) ->
      result = new Varying(initial)
      handler = (event) -> result.set(eventMap[event.type])
      jq.on(k, handler) for k of eventMap
      destroyer(->
        jq.off(k, handler) for k of eventMap
        return
      )
      result
    )
}

module.exports = varyingUtils

