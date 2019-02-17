
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

# http://stackoverflow.com/questions/1007981/how-to-get-function-parameter-names-values-dynamically-from-javascript
STRIP_COMMENTS = /(\/\/.*$)|(\/\*[\s\S]*?\*\/)|(\s*=[^,\)]*(('(?:\\'|[^'\r\n])*')|("(?:\\"|[^"\r\n])*"))|(\s*=[^,\)]*))/mg
ARGUMENT_NAMES = /([^\s,]+)/g
getArguments = (f) ->
  s = f.toString().replace(STRIP_COMMENTS, '')
  s.slice(s.indexOf('(') + 1, s.indexOf(')')).match(ARGUMENT_NAMES) ? []

deindent = (s) ->
  minIndent = 999 # i'd love to see the code that breaks this line.
  lines = s.split('\n')
  rest = lines.slice(1)
  for line in rest
    indent = /^( +)/.exec(line)[1]?.length
    minIndent = indent if indent < minIndent
  [ lines[0] ].concat(line.slice(minIndent) for line in rest).join('\n')

module.exports = {
  pluralize, exists, stringify, getArguments, deindent
}

