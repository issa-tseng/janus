{ Model, Case } = require('janus')

class WrappedCase extends Model
  isInspector: true

  constructor: (kase) -> super({ case: kase })
  _initialize: ->
    this.set('name', this.get('case').name)

  @wrap: (kase) -> new WrappedCase(kase)

module.exports = {
  WrappedCase,
  registerWith: (library) -> library.register(Case, WrappedCase.wrap)
}

