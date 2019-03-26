{ Library } = require('janus')
{ stringify } = require('./util')
{ isPlainObject } = require('janus').util

# get inspectors and create inspect().
inspectorLibrary = new Library()
require('./case/inspector').registerWith(inspectorLibrary)
require('./dom-view/inspector').registerWith(inspectorLibrary)
require('./function/inspector').registerWith(inspectorLibrary)
require('./list/inspector').registerWith(inspectorLibrary)
require('./literal/inspector').registerWith(inspectorLibrary)
require('./model/inspector').registerWith(inspectorLibrary)
require('./varying/inspector').registerWith(inspectorLibrary)

# one little special case: plain objects are too dangerous to register in the
# library so instead we trap it here and deal with it.
inspect = (x) ->
  # TODO: actual entity/panel for plain Object.
  if isPlainObject(x) then stringify(x)
  else if x?.destroyed is true then null # TODO: show something here.
  else inspectorLibrary.get(x)?(x) ? x

module.exports = { inspect }

