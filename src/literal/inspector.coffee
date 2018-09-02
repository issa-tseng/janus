{ isPrimitive, isArray } = require('janus').util

inspectLiteral = (x) ->
  if isPrimitive(x) or isArray(x)
    JSON.stringify(x)
  else if !x?
    'Ø'
  else
    x

module.exports = {
  registerWith: (library) ->
    library.register(type, inspectLiteral) for type in [ String, Number, Boolean, null ]
    return
}

