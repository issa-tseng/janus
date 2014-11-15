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


# sentinel value.
otherwise = 'otherwise'


# the main constructor.
caseSet = (inTypes...) ->
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
        unapply: (x) -> if isFunction(x) then x(this.value) else x
        toString: -> "#{this}: #{this.value}"

      # make the wrapper.
      kase = (value) ->
        instance = new String('' + type)
        instance.value = value

        # decorate set-based methods:
        for fType of types
          do (fType) ->
            # decorate TOrElse:
            instance[fType + 'OrElse'] = (x) -> if type is fType then this.value else x

            # decorate flatT:
            instance['flat' + capitalize(fType)] = -> if type is fType then this.value else this

        # decorate the rest:
        instance.case = kase
        instance[prop] = val for prop, val of extendNew(props, caseProps)

        # return the instance.
        instance

      # decorate some things to help us find ourselves.
      kase.type = type
      kase.set = set

      # add the wrapper.
      set[type] = kase

  # return.
  set


# general unapply handler.
unapply = (target, handler) -> if isFunction(handler) then target?.unapply(handler) else handler


# our matcher.
match = (args...) ->
  set = args[0]?.set # assume the first thing is a case.
  seen = {} # track what cases we've covered.
  otherwise = false # does an otherwise exist?

  # "compile-time" checks.
  for i in [0..args.length] by 2 when args[i]?
    kase = args[i]

    if kase is 'otherwise'
      otherwise = true
    else
      throw new Error("found a case of some other set!") unless set[kase.type]?
      seen[kase.type] = true

  throw new Error('not all cases covered!') for kase of set when seen[kase] isnt true if otherwise is false

  # our actual matcher as a result.
  (target) ->
    # walk pairwise.
    for i in [0..args.length] by 2
      kase = args[i]
      handler = args[i + 1]

      # always process on otherwise.
      return unapply(target, handler) if kase is 'otherwise'

      # process if a match otherwise.
      return unapply(target, handler) if kase.type.valueOf() is target?.valueOf()


# export.
module.exports = { caseSet, match, otherwise }

