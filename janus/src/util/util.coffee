# The util class provides a collection of helpful utilities. This is to the
# absolute shock and horror of everyone opening this file.

# Base util object.
util =

  #### Detection
  # (more are added in bulk below.)
  isArray: Array.isArray ? (obj) -> toString.call(obj) is '[object Array]'
  isNumber: (obj) -> toString.call(obj) is '[object Number]' and !isNaN(obj)
  isPlainObject: (obj) -> obj? and Object.getPrototypeOf(obj) is Object.prototype
  isPrimitive: (obj) -> util.isString(obj) or util.isNumber(obj) or obj is true or obj is false


  #### Number Utils
  # Counter for `uniqueId()`
  _uniqueId: 0

  # Provision a unique serial id.
  # TODO: possibly return an alphanumeric identifier instead.
  uniqueId: -> util._uniqueId++

  #### Array Utils
  # Capitalize the first letter of a string.
  capitalize: (x) -> x.charAt(0).toUpperCase() + x.slice(1) if x?

  #### Function Utils
  # Fixed point Y combinator.
  fix: (f) -> ((x) -> f((y) -> x(x)(y)))((x) -> f((y) -> x(x)(y)))

  # Self-explanatory.
  identity: (x) -> x

  # Doesn't work good for methods, but great for funcs:
  curry2: (f) -> (x, y) ->
    if arguments.length is 2 then f(x, y)
    else (y) -> f(x, y)


  #### Array Utils
  # Exactly what you think it is.
  foldLeft: (value) -> (arr, f) ->
    (value = f(value, elem)) for elem in arr
    value


  #### Object Utils
  # Basic shallow copy in emulation of simplest jQuery extend case. warning: mutates!
  extend: (dest, srcs...) -> (dest[k] = v for k, v of src) for src in srcs; null

  # Check if an object has any k/v pairs at all.
  isEmptyObject: (obj) ->
    return false unless obj?
    (return false) for _ of obj
    return true

  # Get the superclass of a class. Accounts for ES6, Coffeescript, and Livescript.
  superClass: (klass) ->
    if Object.hasOwnProperty.call(klass, 'superclass')
      klass.superclass
    else if Object.hasOwnProperty.call(klass, '__super__')
      klass.__super__.constructor
    else
      result = Object.getPrototypeOf(klass)
      result if result.prototype?


  # Gets a deeply nested key from a hash. Falls back to `null` if it can't find
  # the key in question.
  deepGet: (obj, path) ->
    path = if util.isArray(path) then path else if util.isString(path) then path.split('.') else [ path.toString() ]

    idx = 0
    obj = obj[path[idx++]] while obj? and idx < path.length
    obj ? null # Return null rather than undef here

  # Gives a function to set a deeply nested key in a hash. Eagerly generates
  # nested objects along the way if it encounters undef keys.
  deepSet: (obj, path) ->
    path = if util.isArray(path) then path else if util.isString(path) then path.split('.') else [ path.toString() ]

    idx = 0
    obj = obj[path[idx++]] ?= {} while (idx + 1) < path.length

    (x) -> obj[path[idx]] = x

  # Deletes a deeply nested key in a hash. Aborts if it can't navigate to the
  # path in question.
  deepDelete: (obj, path) ->
    path = if util.isArray(path) then path else path.split('.')

    idx = 0
    obj = obj[path[idx++]] while (idx + 1) < path.length and obj?

    return unless idx is path.length - 1
    return unless obj?

    oldValue = obj[path[idx]]
    delete obj[path[idx]]
    oldValue


  # Traverses a hash, calling a passed-in function with the current path and
  # value for leaves.
  traverse: (obj, f, path = []) ->
    for k, v of obj
      subpath = path.concat([ k ])

      if v? and util.isPlainObject(v)
        util.traverse(v, f, subpath)
      else
        f(subpath, v)
    return

  # Traverses a hash, calling a passed-in function with the current path and
  # value for every node.
  traverseAll: (obj, f, path = []) ->
    for k, v of obj
      subpath = path.concat([ k ])

      f(subpath, v)
      util.traverseAll(obj[k], f, subpath) if obj[k]? and util.isPlainObject(obj[k])
    return

# Bulk add a bunch of detection functions; thanks to Underscore.js.
toString = Object.prototype.toString
for type in [ 'Arguments', 'Function', 'String', 'Date', 'RegExp' ]
  do (type) ->
    util['is' + type] = (obj) -> toString.call(obj) is "[object #{type}]"
    
# Thanks to Underscore again; optimize isFunction if possible.
(util.isFunction = (obj) -> typeof obj is 'function') if typeof (/./) isnt 'function'


module.exports = util

