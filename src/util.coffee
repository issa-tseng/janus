
pluralize = (single, many) -> (num) ->
  if typeof num is 'number'
    if num is 1 then single else many
  # otherwise just return nothing, we don't have anything to label.

exists = (x) -> x? and (x isnt '')

stringify = (obj) ->
  try
    return JSON.stringify(obj)
  catch
    return "Object[#{Object.keys(obj).length} pairs]"

module.exports = {
  pluralize, exists, stringify
}

