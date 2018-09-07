
pluralize = (single, many) -> (num) ->
  if typeof num is 'number'
    if num is 1 then single else many
  # otherwise just return nothing, we don't have anything to label.

exists = (x) -> x? and (x isnt '')

module.exports = {
  pluralize, exists
}

