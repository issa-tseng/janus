{ List, dēfault } = require('janus')
{ TruncatingLiteral } = require('./entity-view')
{ isPrimitive, isArray } = require('janus').util
{ WrappedList } = require('../list/inspector')


inspectLiteral = (x) ->
  if isPrimitive(x)
    string = JSON.stringify(x)
    # we use 350 here but 300 in the actual truncation so we don't do silly things
    # like truncate only by one char.
    if string.length > 350 then new TruncatingLiteral({ string })
    else string
  else if !x?
    'Ø'
  else
    x


class WrappedArray extends WrappedList.build(dēfault('type', 'Array'))
  @wrap: (array) -> new WrappedArray(new List(array))

wrapArray = (array) -> WrappedArray.wrap(array)


module.exports = {
  registerWith: (library) ->
    library.register(type, inspectLiteral) for type in [ String, Number, Boolean, null ]
    library.register(Array, wrapArray)
    return
}

