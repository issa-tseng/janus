types = require('../core/types')
{ Base } = require('../core/base')
{ Varying } = require('../core/varying')
{ List } = require('../collection/list')


# all things being equal, i'd rather this just be a function that returns
# Varying[types.result[x]]. but we also want to track and return what requests
# were made and their results, so we make a class as a holding box.
class Manifest extends Base
  constructor: (app, @model, criteria, options) ->
    super()
    self = this
    this.app = app.shadow() # get our own events.

    this._valid = true
    this.result = new Varying(types.result.init())
    this.requests = new List()
    this.requests.destroyWith(this)

    # track app request resolution. set hook if we might be done.
    this._pending = 0
    this.listenTo(this.app, 'resolvedRequest', (request, result) =>
      this._pending += 1
      this.requests.add({ request, result })
      this.reactTo(result, (inner) ->
        return unless types.result.complete.match(inner)
        self._pending -= 1
        self._hook()
        this.stop()
      )
    )

    # track model issue state. if anything is actually wrong we'll pick it up
    # and return it when the hook fires.
    if this.model.valid?
      this.reactTo(this.model.valid(), (isValid) => this._valid = isValid)

    # now vend the view; fault if we can't find one.
    this.view = this.app.view(this.model, criteria, options)
    if !this.view?
      return this._fault('internal: could not find view for model')

    # finally set the hook if we might be done, and report that we're working.
    this._hook()
    this.result.set(types.result.pending())

  # set speculatively when we might be done with all pending requests. will not
  _hook: ->
    return if this._pending > 0
    return if this._hooked is true
    this._hooked = true

    setTimeout((=>
      this._hooked = false
      return if this._fault is true
      return if this._pending > 0

      # we are definitely done, just figure out in what state:
      if this._valid is true
        this.result.set(types.result.success(this.view))
      else
        this.result.set(types.result.failure(this.model.issues()))

      this.destroy()
      return
    ), 0)
    return

  _fault: (x) ->
    this._fault = true
    this.result.set(types.result.failure(x))
    this.destroy() # immediately stop listening to things.
    return

  @run: (app, model, criteria, options) -> new this(app, model, criteria, options)


module.exports = { Manifest }

