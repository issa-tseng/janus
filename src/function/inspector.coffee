{ Model, List } = require('janus')
{ getArguments } = require('../util')

class Applicant extends Model

class WrappedFunction extends Model
  isInspector: true
  isWrappedFunction: true
  constructor: (f, args, options) ->
    super()

    # functions can't change, so we just statically precompute some stuff, including
    # argument names and value mappings.
    this.set('target', f)
    this.set('arg.given', args?)
    args = [] unless args?

    this.set('arg.names', getArguments(f))
    this.set('arg.values', args)

    pairs = new List(new Applicant({ name, value: args[idx] }) for name, idx in this.get_('arg.names'))
    this.set('arg.pairs', pairs)

  @wrap: (f, args) -> if (f.isWrappedFunction is true) then f else (new WrappedFunction(f, args))

module.exports = {
  Applicant,
  WrappedFunction,
  registerWith: (library) ->
    library.register(Function, WrappedFunction.wrap)
}

