# The util class provides a collection of helpful utilities. This is to the
# absolute shock and horror of everyone opening this file.

# base util object
util =

  # basic shallow copy in emulation of simplest jQuery extend case. warning: mutates!
  extend: (dest, srcs...) -> (dest[k] = v for k, v of src) for src in srcs; null

# use our freshly-declared extend() to populate our module exports
util.extend(module.exports, util)

