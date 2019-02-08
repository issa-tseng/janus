
# if requestAnimationFrame exists, we use it by default:
animationFrame = (f_) ->
  requested = false
  lastval = null
  (x) ->
    lastval = x
    if requested is false
      window.requestAnimationFrame(=>
        requested = false
        f_.call(this, lastval)
        return
      )
      requested = true
    return

# by default, if requestAnimationFrame does not exist, we just render everything
# synchronously:
synchronous = (f_) -> f_

# when using Manifest, it will manually toggle the queueing mode to batched
# and manage it 

# optionally, if Manifest is not being used but one still wishes to batch render
# ops, one can use the deferred global queue strategy. this is essentially a shim
# for requestAnimationFrame.
deferred = do ->
  timer = null
  generation = 0
  queue = []
  flush = ->
    timer = null
    generation += 1
    flushQueue = queue
    queue = []
    f_() for f_ in flushQueue
    return

  (f_) ->
    thisgen = -1
    lastval = null # TODO: can also do no work if val cycles.
    (x) ->
      lastval = x
      if thisgen < generation
        queue.push(-> f_.call(this, lastval))
        thisgen = generation
      timer ?= setTimeout(flush, 0)
      return

queuer =
  if window?.requestAnimationFrame? then animationFrame
  else synchronous

setMode = (mode) -> queuer = mode

module.exports = { queued: queuer }

