{ TruncatingLiteral } = require('./entity-view')
{ isPrimitive, isArray } = require('janus').util

inspectLiteral = (x) ->
  if isPrimitive(x) or isArray(x)
    string = JSON.stringify(x)
    # we use 350 here but 300 in the actual truncation so we don't do silly things
    # like truncate only by one char.
    if string.length > 350 then new TruncatingLiteral({ string })
    else string
  else if !x?
    'Ø'
  else
    x

module.exports = {
  registerWith: (library) ->
    library.register(type, inspectLiteral) for type in [ String, Number, Boolean, null ]
    return
}

