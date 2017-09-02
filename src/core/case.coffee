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

{ extendNew, capitalize, isPlainObject, isFunction, isArray } = require('../util/util')


# otherwise is a case that like the others can be referenced by string or used
# as a function.
otherwise = (value) -> { type: 'otherwise', value, case: otherwise }
otherwise.type = 'otherwise'


# the main constructor.
defcase = (namespace, inTypes...) ->
  set = {}

  # allow the namespace to be a k/v pair offering default properties for all cases.
  setProps = {}
  if isPlainObject(namespace)
    obj = namespace
    for k, v of obj
      namespace = k
      setProps = v

  # allow for a bare string or a k/v pair, or many k/v pairs.
  # flatten/normalize to obj here.
  types = {}
  process = (params) ->
    for type in params
      if isPlainObject(type)
        for k, v of type
          if isArray(v)
            types[k] = { children: v }
          else
            types[k] = v
          process(types[k].children) if types[k].children?
      else
        types[type] = {}
  process(inTypes)

  # massage the children to be just string arrays.
  # TODO: this is ugly; also the weird variable name iterProps is because
  # coffeescript scoping is super broken.
  for _, iterProps of types when iterProps.children?
    results = []
    for child in iterProps.children
      if isPlainObject(child)
        results.push(k) for k of child
      else
        results.push(child)
    iterProps.children = results

  # process all.
  for type, caseProps of types
    do (type, caseProps) ->
      # the per-case properties we're going to decorate on.
      defaultProps = {
        arity: 1
        map: (f) -> kase(f(this.value))
        toString: -> "#{this.type}: #{this.value}"
        unapply: (x, additional) ->
          if isFunction(x)
            if this.arity is 1
              x(this.value, additional...)
            else if this.arity is 2
              x(this.value, this.value2, additional...)
            else if this.arity is 3
              x(this.value, this.value2, this.value3, additional...)
          else
            x
      }
      props = extendNew(defaultProps, setProps, caseProps)

      # make and cache an instance prototype:
      instance = { type }
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
      instance[prop] = val for prop, val of props

      # eventual final product.
      kase = (x, y, z) ->
        newInstance = Object.create(instance)
        newInstance.value = x
        newInstance.value2 = y if props.arity >= 2
        newInstance.value3 = z if props.arity >= 3
        newInstance

      # reference the case on the instance now that we have it.
      instance.case = kase

      # decorate some things to help us find ourselves.
      kase.isCase = true
      kase.type = type
      kase.set = set
      kase.namespace = namespace

      # decorate direct matcher.
      # TODO: should do namespace verification.
      kase.match = (x, f_) ->
        xtype = x?.type
        matches = (xtype is type) or (kase._allChildren[xtype] is true)
        if isFunction(f_) then (unapply(x, f_, []) if matches) else matches

      # precompute all children for matching later.
      kase._allChildren = {}
      add = (type) ->
        if (children = types[type].children)?
          for child in children
            add(child)
            kase._allChildren[child] = true
      add(type)

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
      break
    else
      throw new Error("found a case of some other set!") unless kase.namespace is namespace
      seen[kase.type] = true
      (seen[child] = true) for child of kase._allChildren if kase._allChildren?

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
        i += 1
      else
        kase = args[i]
        handler = args[i + 1]
        i += 2

      # always process if otherwise.
      if kase.type is 'otherwise'
        return unapply(target, handler, additional, false)

      # process a match if it is in the same namespace and a direct match, or a
      # child of the given matcher case.
      if (target?.case ? target)?.namespace is namespace
        targetName = target?.type
        if (kase.type is targetName) or (kase._allChildren[targetName] is true)
          return unapply(target, handler, additional)

    # don't accumulate.
    null

# export.
module.exports = { defcase, match, otherwise }

