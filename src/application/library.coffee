# The **Library** is a resource tracker. One can register classes or instances
# against it, and recall them via description. This enables flexibility around
# differing implementations of some functional task, such as rendering a model
# in a different context or making a semantically isomorphic network request
# from various environments, without being dependent on direct class reference.
#
# Note that in order to performantly track classtypes, registering a class with
# a library will result in a reference id being stored away upon it.
#
# In a cute piece of metaphor-based naming, the internal tracking object is
# known as a bookcase, the subdivisions therein (first by class then by
# context) are called shelves, and the actual stored objects are books.

util = require('../util/util')
Base = require('../core/base').Base


class Library extends Base
  isLibrary: true

  constructor: () ->
    super()
    this.bookcase = {}

  # Registers a book with the `Library`. Book is the thing that should be handed
  # back when we try to .get(klass). It can be anything. Options can be context,
  # priority (bigger is higher pri), and any arbitrary other k/v pairs for
  # matching on .get().
  register: (klass, book, options = {}) ->
    bookId = Library._classId(klass)

    classShelf = this.bookcase[bookId] ?= {}
    contextShelf = classShelf[options.context ? 'default'] ?= []

    contextShelf.push(
      book: book
      options: options
    )

    contextShelf.sort((a, b) -> (b.options.priority ? 0) - (a.options.priority ? 0)) if options.priority?

    book

  # Given some object, returns the first match in the Library.
  # Takes the target `obj`, and optionally a `criteria` hash containing the
  # `context` and/or attributes pairs to match the registration.
  get: (obj, criteria = {}) ->
    result =
      this._get(obj, obj?.constructor, criteria.context ? 'default', criteria) ?
      this._get(obj, obj?.constructor, 'default', criteria)

    if result?
      this.emit('got', obj, result, criteria)
    else
      this.emit('missed', obj, criteria)

    result ? null

  # Internal recursion method for searching the library.
  _get: (obj, klass, context, criteria) ->
    bookId = Library._instanceClassId(obj) ? Library._classId(klass)
    contextShelf = this.bookcase[bookId]?[context]

    # possible matches; return the first true match.
    if contextShelf?
      for record in contextShelf
        isMatch = true
        for k, v of criteria when k not in [ 'context', 'priority' ]
          if record.options[k] isnt v
            isMatch = false
            break
        return record.book if isMatch is true

    # no match found; go up the inheritance tree and retry.
    if klass?
      if (superClass = util.superClass(klass))?
        return this._get(obj, superClass, context, criteria)

  # Class-level internal tracking of object constructors.
  @classKey: "__janus_classId#{new Date().getTime()}"
  @classMap: {}

  # Class-level method for tagging and reading the tag off of constructors.
  @_classId: (klass) ->
    if !klass?
      'null'
    else if klass is Number
      'number'
    else if klass is String
      'string'
    else if klass is Boolean
      'boolean'
    else
      klass = klass.type if klass.isCase is true

      id = klass[this.classKey]

      if id? and this.classMap[id] is klass
        klass[this.classKey]
      else
        id = util.uniqueId()
        this.classMap[id] = klass
        klass[this.classKey] = id

  # Class-level method for determining the tag of some special-case object
  # instances.
  @_instanceClassId: (obj) ->
    if !obj?
      'null'
    else if util.isNumber(obj)
      'number'
    else if util.isString(obj)
      'string'
    else if obj is true or obj is false
      'boolean'

module.exports = { Library }

