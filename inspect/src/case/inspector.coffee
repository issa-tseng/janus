{ Model, Case } = require('janus')

class WrappedCase extends Model
  isInspector: true
  constructor: (target, options) -> super({ target, name: target.name }, options)
  @wrap: (kase) -> new WrappedCase(kase)

module.exports = {
  WrappedCase,
  registerWith: (library) -> library.register(Case, WrappedCase.wrap)
}

