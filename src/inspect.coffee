{ Library } = require('janus')
{ isPlainObject } = require('janus').util

# get inspectors and create inspect().
inspectorLibrary = new Library()
require('./case/inspector').registerWith(inspectorLibrary)
require('./list/inspector').registerWith(inspectorLibrary)
require('./literal/inspector').registerWith(inspectorLibrary)
require('./model/inspector').registerWith(inspectorLibrary)
require('./varying/inspector').registerWith(inspectorLibrary)

# one little special case: plain objects are too dangerous to register in the
# library so instead we trap it here and deal with it.
inspect = (x) ->
  if isPlainObject(x) then JSON.stringify(x)
  else inspectorLibrary.get(x)?(x) ? x

module.exports = { inspect }

