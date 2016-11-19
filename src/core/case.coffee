# case.coffee -- case classes for the poor.
#
# So, in many cases one wants to encode a type of result and an inner value of
# the result. Because this isn't Scala, one cannot simply use case classes. So,
# the first version of Janus simply used normal classes and instanceof to check
# their values.
#
# Unfortunately, npm makes this approach really tricky. Each instance of Janus,
# and each instance of any intermediate Janus-based library, gets its own type
# class which while morally equivalent cannot be checked with an instanceof.
# So we have to use something out there, or make our own. Everything out there
# is a lot more interested in fancy magicks like matching expressions and
# destructuring regexes, which I don't care about, so we roll our own.
#
# I really hate how heavyweight and wheel-reinventy this is. My first attempt
# was to sugar plain strings with methods and inner values, such that one could
# still just use a standard switch case on them, and it would be super light-
# weight. But string primitives and wrapped string objects are not the same,
# and whilst only a wrapped object may have methods and properties, only a
# primitive will behave as expected when doing a switch case owing to primitive
# vs reference comparison.
#
# So, we have this heavier, more featureful version, because hey we're already
# out of simplicity-land so why not?

{ extendNew, capitalize, isPlainObject, isFunction } = require('../util/util')


# otherwise is a case that like the others can be referenced by string or used
# as a function.
otherwise = (value) ->
  instance = new String('otherwise')
  instance.value = value
  instance.case = otherwise
  instance
otherwise.type = 'otherwise'


# the main constructor.
defcase = (namespace, inTypes...) ->
  set = {}

  # allow for a bare string or a k/v pair, or many k/v pairs.
  # flatten/normalize to obj here.
  types = {}
  for type in inTypes
    if isPlainObject(type)
      types[k] = v for k, v of type
    else
      types[type] = {}

  # process all.
  for type, caseProps of types
    do (type, caseProps) ->
      # the per-case properties we're going to decorate on.
      props =
        map: (f) -> kase(f(this.value))
        unapply: (x, additional) -> if isFunction(x) then x(this.value, additional...) else x
        toString: -> "#{this}: #{this.value}"

      # make the wrapper.
      kase = (value) ->
        instance = new String('' + type)
        instance.type = type
        instance.value = value

        # decorate set-based methods:
        for fType of types
          do (fType) ->
            # decorate TOrElse:
            instance[fType + 'OrElse'] = (x) -> if type is fType then this.value else x

            # decorate getT:
            instance['get' + capitalize(fType)] = -> if type is fType then this.value else this

            # decorate mapT:
            instance['map' + capitalize(fType)] = (f) -> if type is fType then kase(f(this.value)) else this

        # decorate the rest:
        instance.case = kase
        instance[prop] = val for prop, val of extendNew(props, caseProps)

        # return the instance.
        instance

      # decorate some things to help us find ourselves.
      kase.isCase = true
      kase.type = type
      kase.set = set
      kase.namespace = namespace

      # decorate direct matcher.
      kase.match = (x, f_) ->
        matches = x?.type is type
        if isFunction(f_) then (f_(x.value) if matches) else matches

      # add the wrapper.
      set[type] = kase

  # return.
  set


# general unapply handler.
unapply = (target, handler, additional, unapply = true) ->
  if isFunction(handler)
    if isFunction(target?.unapply) and unapply is true
      target.unapply(handler, additional)
    else
      handler(target, additional...)
  else
    handler


# our matcher.
match = (args...) ->
  first = args[0] # grab the first item.
  set = (first?.case ? first)?.set # assume the first thing is a case or an instance.
  namespace = (first?.case ? first)?.namespace # ditto.
  seen = {} # track what cases we've covered.
  hasOtherwise = false # does an otherwise exist?

  # "compile-time" checks.
  i = 0
  while i < args.length
    x = args[i]
    kase = if x.case? then x.case else x

    if kase.type is 'otherwise'
      hasOtherwise = true
    else
      throw new Error("found a case of some other set!") unless kase.namespace is namespace
      seen[kase.type] = true

    i += if x.case? then 1 else 2

  throw new Error('not all cases covered!') for kase of set when seen[kase] isnt true if hasOtherwise is false

  # our actual matcher as a result.
  (target, additional...) ->
    # walk pairwise.
    i = 0
    while i < args.length
      x = args[i]
      if x.case?
        kase = x.case
        handler = x.value
      else
        kase = args[i]
        handler = args[i + 1]

      # always process if otherwise.
      return unapply(target, handler, additional, false) if kase.type is 'otherwise'

      # process if a match if not. TODO: checking set ref against set ref breaks npm-agnosticity.
      return unapply(target, handler, additional) if kase.type.valueOf() is target?.valueOf() and (target?.case ? target)?.namespace is namespace

      i += if x.case? then 1 else 2

# export.
module.exports = { defcase, match, otherwise }

