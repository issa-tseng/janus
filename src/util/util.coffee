{ Varying, List } = require('janus')
{ isArray } = require('janus').util

# standard resolution for converting values to text for the ui; prefers a stringify
# passed directly on the view options. then on the attribute, then finally just tries
# to call toString on the value otherwise.
stringifier = (view) ->
  if view.options.stringify?
    Varying.of(view.options.stringify)
  else if view.subject.stringify?
    Varying.of(view.subject.stringify)
  else
    new Varying((x) -> x?.toString() ? '')

# standard resolution for taking a value and trying to derive a List out of it.
asList = (x) ->
  if !x?
    new List()
  else if isArray(x)
    new List(x)
  else if x.isCollection
    x
  else
    console.error('got an unexpected value for EnumAttribute#values')
    new List()

module.exports = { stringifier, asList }

