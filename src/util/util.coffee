# The util class provides a collection of helpful utilities. This is to the
# absolute shock and horror of everyone opening this file.

# Base util object.
util =

  #### Detection
  # (more are added in bulk below.)
  isArray: Array.isArray ? (obj) -> toString.call(obj) is '[object Array]'
  isNumber: (obj) -> toString.call(obj) is '[object Number]' and !isNaN(obj)
  isPlainObject: (obj) -> (typeof obj is 'object') and (obj.constructor is Object)


  #### Number Utils
  # Counter for `uniqueId()`
  _uniqueId: 0

  # Provision a unique serial id.
  #
  # **Returns** a unique integer.
  uniqueId: -> util._uniqueId++


  #### Object Utils
  # Basic shallow copy in emulation of simplest jQuery extend case. warning: mutates!
  extend: (dest, srcs...) -> (dest[k] = v for k, v of src) for src in srcs; null


  # Helper used by `deepGet` and `deepSet` to standardize the path argument.
  # Accepts `x, y, z`, `'x.y.z'`, and `[x, y, z]`.
  #
  # **Returns** an array of string path components.
  normalizePath: (path) ->
    if path.length isnt 1
      path
    else
      if util.isString(path[0])
        path[0].split('.')
      else if util.isArray(path[0])
        path[0]

  # Gets a deeply nested key from a hash. Falls back to `null` if it can't find
  # the key in question.
  #
  # **Returns** the value in question, or else `null`.
  deepGet: (obj, path...) ->
    path = util.normalizePath(path)
    return null unless path?

    obj = obj[path.shift()] while obj? and path.length > 0
    obj ? null # Return null rather than undef here

  # Sets a deeply nested key in a hash. Generates nested hashes along the way
  # if it encounters undef keys.
  #
  # **Returns** a function that takes:
  #
  # - a value and sets the requested key, or
  # - a function, which will be called with the object the key lives on, and
  #   the key.
  deepSet: (obj, path...) ->
    path = util.normalizePath(path)
    return null unless path?

    obj = obj[path.shift()] ?= {} while path.length > 1

    (x) ->
      if util.isFunction(x)
        x()
      else
        obj[path[0]] = x


  # Traverses a hash, calling a passed-in function with the current path and
  # value for leaves.
  #
  # **Returns** The original hash.
  traverse: (obj, f, path = []) ->
    for k, v of obj
      subpath = path.concat([ k ])

      if util.isPlainObject(v)
        f(subpath, v)
      else
        traverse(v, f, subpath)

    obj

# Bulk add a bunch of detection functions; thanks to Underscore.js.
for type in [ 'Arguments', 'Function', 'String', 'Date', 'RegExp' ]
  do (type) ->
    util['is' + type] = (obj) -> toString.call(obj) is "[object #{type}]"

# Use our freshly-declared `extend()` to populate our module exports.
util.extend(module.exports, util)

