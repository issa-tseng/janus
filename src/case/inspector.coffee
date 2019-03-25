{ Model, Case } = require('janus')

class WrappedCase extends Model
  isInspector: true

  constructor: (target) -> super({ target })
  _initialize: ->
    this.set('name', this.get('target').name)

  @wrap: (kase) -> new WrappedCase(kase)

module.exports = {
  WrappedCase,
  registerWith: (library) -> library.register(Case, WrappedCase.wrap)
}

