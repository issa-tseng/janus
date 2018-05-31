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
  _defaultContext: 'default'

  # Initializes a `Library`. Libraries can be initialized with some options:
  #
  # - `handler`: Defines what to do with a registered book when it is
  #   retrieved. By default, it assumes books are constructors with which a
  #   new instance should be initialized with the target object as a parameter,
  #   and returned to the user.
  #   It is given `(obj, book, options)`, where `options` are the options given
  #   the `get()` method.
  #
  constructor: (@options = {}) ->
    super()

    this.bookcase = {}

    this.options.handler ?= (obj, book, options) -> new book(obj, util.extendNew(options.options, libraryContext: options.context))

  # Registers a book with the `Library`. It takes some fixed parameters:
  #
  # 1. `klass`: The class of target objects that ought to be matched with this
  #    book. The library will match contravariants of the given type.
  # 2. `book`: The actual entity to return to the user upon match. By default,
  #    this is assumed to be a constructor (see `handler` option in the
  #    constructor), but it can be anything.
  # 3. `options`: *Optional*: A hash with any of the following additional
  #    options:
  #    - `context`: A string denoting what sort of match we're looking
  #      for. This can be anything; recommended usages involve logical rather
  #      than physical differences; eg "default" vs "edit" is best practice,
  #      whereas "client" vs "server" is better resolved by registration itself.
  #    - `priority`: A positive integer denoting the priority of this
  #      registration. The higher the value, the higher the priority.
  #    - `attributes`: An additional set of descriptive attributes in hash
  #      form. This can be arbitrarily nested, but values will be compared with
  #      strict equality.
  #    - `rejector`: After a basic match, the `rejector` is called and passed in
  #      the target object. Returning `true` will fail the match.
  #    - `acceptor`: After a basic match, the `acceptor` is called and passed in
  #      the target object. Returning anything but `true` will fail the match.
  #
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

  # The big show. Given some object, returns the first match in the Library.
  # Takes the target `obj`, and optionally an `options` hash containing the
  # `context` and/or an `attributes` hash to match the registration.
  #
  # **Returns** a registered book, processed by the Library's `handler`.
  get: (obj, options = {}) ->
    debugger if options.debug is true

    book =
      this._get(obj, obj?.constructor, options.context ? this._defaultContext, options) ?
      this._get(obj, obj?.constructor, 'default', options)

    if book?
      result = (options.handler ? this.options.handler)(obj, book, options)
      this.emit('got', result, obj, book, options)
    else
      this.emit('missed', obj, options)

    result ? null

  # Internal recursion method for searching the library.
  _get: (obj, klass, context, options) ->
    bookId =
      if !obj?
        'null'
      else if obj.case?
        "case@#{obj.case.namespace}.#{obj.type}"
      else if obj.isCase is true
        "case@#{obj.namespace}.#{obj.type}"
      else if util.isNumber(obj)
        'number'
      else if util.isString(obj)
        'string'
      else if obj is true or obj is false
        'boolean'
      else
        Library._classId(klass)
    contextShelf = this.bookcase[bookId]?[context]

    if contextShelf?
      # we have a set of possible matches. go through them.
      return record.book for record in contextShelf when match(obj, record, options.attributes)

    if klass? and util.superClass(klass)?
      this._get(obj, util.superClass(klass), context, options)

  # Class-level internal tracking of object constructors.
  @classKey: "__janus_classId#{new Date().getTime()}"
  @classMap: {}

  # Class-level method for tagging and reading the tag off of constructors.
  @_classId: (klass) ->
    if !klass?
      'null'
    else if klass.case?
      "case@#{klass.case.namespace}.#{klass.type}"
    else if klass.isCase is true
      "case@#{klass.namespace}.#{klass.type}"
    else if klass is Number
      'number'
    else if klass is String
      'string'
    else if klass is Boolean
      'boolean'
    else
      id = klass[this.classKey]

      if id? and this.classMap[id] is klass
        klass[this.classKey]
      else
        id = util.uniqueId()
        this.classMap[id] = klass
        klass[this.classKey] = id

# Internal util func for processing a potential match against its advanced
# options.
match = (obj, record, attributes) ->
  return false unless record.options.rejector?(obj) isnt true
  return false if record.options.acceptor? and (record.options.acceptor(obj) isnt true)

  isMatch = true
  util.traverse(attributes, (subpath, value) -> isMatch = false unless util.deepGet(record.options.attributes, subpath) is value) if attributes

  isMatch


module.exports = { Library }

