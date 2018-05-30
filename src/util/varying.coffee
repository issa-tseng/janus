{ Varying, Base } = require('janus')

nothing = {}

class ManagedObservation extends Base
  constructor: (@varying) -> super()
  react: (f_) -> this.reactTo(this.varying, f_)
  reactLater: (f_) -> this.reactLaterTo(this.varying, f_)
  @with: (varying) -> -> new ManagedObservation(varying)

varyingUtils = {
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

  throttle: (delay, v) ->
    return ((v) -> varyingUtils.throttle(delay, v)) unless v?

    Varying.managed(ManagedObservation.with(v), (mo) ->
      result = new Varying(v.get())

      timer = null
      pendingValue = nothing
      mo.reactLater((value) ->
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

  fromEvent: (jq, event, f, immediate = false) ->
    destroyer = (d_) -> destroyer.destroy = d_
    Varying.managed((-> destroyer), ((destroyer) ->
      result = new Varying()

      f_ = (event) -> result.set(f.call(this, event))
      f_() if immediate
      jq.on(event, f_)
      destroyer(-> jq.off(event, f_))

      result
    ))

  fromEventNow: (jq, event, f) -> varyingUtils.fromEvent(jq, event, f, true)
}

module.exports = varyingUtils

