{ Varying, Model, List } = require('janus')
{ getArguments } = require('../util')


################################################################################
# KNOWN FUNCTIONS

known = {}
do ->
  # map/model data setter
  known[(new Model()).set('x').toString()] = 'map/model data setter'

  # varying inner handler
  v = new Varying()
  (new Varying()).flatMap(-> v).react()
  (known[o.f_.toString()] = 'flattened varying value handler') for _, o of v._observers


################################################################################
# FUNCTION INSPECTOR

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

    this.set('known', known[f.toString()])

  @wrap: (f, args) -> if (f.isWrappedFunction is true) then f else (new WrappedFunction(f, args))

module.exports = {
  Applicant,
  WrappedFunction,
  registerWith: (library) ->
    library.register(Function, WrappedFunction.wrap)
}

