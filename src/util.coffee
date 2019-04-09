{ parse } = require('cherow')

noop = (->)
identity = (x) -> x

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

getArguments = (f) ->
  try
    # we always assign to f to guard against anonymous function decl failure:
    tree = parse('f = ' + f.toString())
    fexpr = tree.body[0].expression.right # navigate into that assignment
    return (param.name for param in fexpr.params)
  catch
    return []

deindent = (s) ->
  minIndent = 999 # i'd love to see the code that breaks this line.
  lines = s.split('\n')
  rest = lines.slice(1)
  for line in rest
    indent = /^( +)/.exec(line)?[1]?.length
    minIndent = indent if indent < minIndent
  [ lines[0] ].concat(line.slice(minIndent) for line in rest).join('\n')

module.exports = {
  noop, identity, pluralize, exists, stringify, getArguments, deindent
}

