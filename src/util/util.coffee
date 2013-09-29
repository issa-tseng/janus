# The util class provides a collection of helpful utilities. This is to the
# absolute shock and horror of everyone opening this file.

# Base util object.
util =

  #### Detection
  # (more are added in bulk below.)
  isArray: Array.isArray ? (obj) -> toString.call(obj) is '[object Array]'
  isNumber: (obj) -> toString.call(obj) is '[object Number]' and !isNaN(obj)
  isPlainObject: (obj) -> obj? and (typeof obj is 'object') and (obj.constructor is Object)
  isPrimitive: (obj) -> util.isString(obj) or util.isNumber(obj) or obj is true or obj is false


  #### Number Utils
  # Counter for `uniqueId()`
  _uniqueId: 0

  # Provision a unique serial id.
  #
  # TODO: possibly return an alphanumeric identifier instead.
  #
  # **Returns** a unique integer.
  uniqueId: -> util._uniqueId++



  #### Function Utils
  # Very simple call limiters.
  once: (f) ->
    run = false
    (args...) ->
      return if run is true
      run = true
      f(args...)



  #### Array Utils
  # Exactly what you think it is.
  foldLeft: (value) -> (arr, f) ->
    (value = f(value, elem)) for elem in arr
    value

  # Still exactly what you think it is.
  reduceLeft: (arr, f) -> util.foldLeft(arr[0])(arr, f)

  # Also pretty obvious.
  first: (arr) -> arr[0]
  last: (arr) -> arr[arr.length - 1]

  # Pull out an item and replace it with one or more items. Appends to the end
  # of the list if the element is not found.
  resplice: (arr, pull, push) ->
    idx = arr.indexOf(pull)
    idx = arr.length if idx < 0

    arr.splice(idx, 1, push...)


  #### Object Utils
  # Basic shallow copy in emulation of simplest jQuery extend case. warning: mutates!
  extend: (dest, srcs...) -> (dest[k] = v for k, v of src) for src in srcs; null

  # Nonmutating version of extend; extends into a new obj that's returned.
  extendNew: (srcs...) ->
    obj = {}
    util.extend(obj, srcs...)
    obj

  # Check if an object has any properties at all.
  hasProperties: (obj) ->
    (return true) for k of obj when obj.hasOwnProperty(k)
    false


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

    idx = 0
    obj = obj[path[idx++]] while obj? and idx < path.length
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

    idx = 0
    while (idx + 1) < path.length
      obj = obj[path[idx]] ?= {}
      idx++

    (x) ->
      if util.isFunction(x)
        x(obj, path[idx])
      else
        obj[path[idx]] = x


  # Traverses a hash, calling a passed-in function with the current path and
  # value for leaves.
  #
  # **Returns** The original hash.
  traverse: (obj, f, path = []) ->
    for k, v of obj
      subpath = path.concat([ k ])

      if v? and util.isPlainObject(v)
        util.traverse(v, f, subpath)
      else
        f(subpath, v)

    obj

  # Traverses a hash, calling a passed-in function with the current path and
  # value for every node.
  #
  # **Returns** The original hash.
  traverseAll: (obj, f, path = []) ->
    for k, v of obj
      subpath = path.concat([ k ])

      f(subpath, v)
      util.traverseAll(obj[k], f, subpath) if obj[k]? and util.isPlainObject(obj[k])

    obj

# Bulk add a bunch of detection functions; thanks to Underscore.js.
toString = Object.prototype.toString
for type in [ 'Arguments', 'Function', 'String', 'Date', 'RegExp' ]
  do (type) ->
    util['is' + type] = (obj) -> toString.call(obj) is "[object #{type}]"
    
# Thanks to Underscore again; optimize isFunction if possible.
(util.isFunction = (obj) -> typeof obj is 'function') if typeof (/./) isnt 'function'

# Use our freshly-declared `extend()` to populate our module exports.
util.extend(module.exports, util)

