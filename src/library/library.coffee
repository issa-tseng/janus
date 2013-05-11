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

util = require('util')

class Library
  # Initializes a `Library`. Libraries can be initialized with some options:
  #
  # - `handler`: Defines what to do with a registered book when it is
  #   retrieved. By default, it assumes books are constructors with which a
  #   new instance should be initialized with the target object as a parameter,
  #   and returned to the user.
  #
  constructor: (@options = {}) ->
    this.bookcase = {}

    this.options.handler ?= (obj, book) -> new book(obj)

  # Registers a book with the `Library`. It takes some fixed parameters:
  #
  # 1. `klass`: The class of target objects that ought to be matched with this
  #    book. The library will match contravariants of the given type.
  # 2. `book`: The actual entity to return to the user upon match. By default,
  #    this is assumed to be a constructor (see `handler` option in the
  #    constructor), but it can be anything.
  # 3. `context`: *Optional*: A string denoting what sort of match we're looking
  #    for. This can be anything; recommended usages include 'client' vs
  #    'server', 'default' vs 'edit', etc.
  # 4. `options`: *Optional*: A hash with any of the following additional
  #    options:
  #    - `priority`: A positive integer denoting the priority of this
  #      registration. The higher the value, the higher the priority.
  #    - `attributes`: An additional set of descriptive attributes in hash
  #      form. This can be arbitrarily nested, but values will be compared with
  #      strict equality.
  #    - `rejector`: After a basic match, the `rejector` is called and passed in
  #      the target object. Returning `true` will fail the match.
  #    - `acceptor`: After a basic match, the `acceptor` is called and passed in
  #      the target object. Returning anything but `true` will fail the match.
  register: (klass, book, context = 'default', options = {}) ->
    bookId = Library._classId(klass)

    classShelf = this.bookcase[bookId] ?= {}
    contextShelf = classShelf[context] ?= []

    contextShelf.push(
      book: book
      options: options
    )

    contextShelf.sort((a, b) -> (b.options.priority ? 0) - (a.options.priority ? 0)) if options.priority?

    book

  # The big show. Given some object, returns the first match in the Library.
  # Takes the target `obj`, and optionally the string `context` and an
  # `attributes` hash.
  #
  # **Returns** a registered book, processed by the Library's `handler`.
  get: (obj, context = 'default', attributes = {}) ->
    result =
      this._get(obj, obj.constructor, context, attributes) ?
      this._get(obj, obj.constructor, 'default', attributes)
    this.options.handler(result) if result?

  # Internal recursion method for searching the library.
  _get: (obj, klass, context, attributes) ->
    klass = obj.constructor
    bookId = Library._classId(klass)
    contextShelf = this.bookcase[bookId]?[context]

    if contextShelf?
      # we have a set of possible matches. go through them.
      return this.handler(record.book) for record in contextShelf when match(record, attributes)

    if klass.__super__?
      this._get(obj, klass.__super__.constructor, context, attributes)

  # Class-level internal tracking of object constructors.
  @classKey: "__janus_classId#{new Date().getTime()}"
  @classMap: {}

  # Class-level method for tagging and reading the tag off of constructors.
  @_classId: (klass) ->
    if klass[this.classKey]? and this.classMap[this.classKey] is klass
      klass[this.classKey]
    else
      id = util.uniqueId()
      this.classMap[id] = klass
      klass[this.classKey] = id

# Internal util func for processing a potential match against its advanced
# options.
match = (record, attributes) ->
  return false unless record.options.rejector?(obj) isnt true
  return false if record.options.acceptor? and (record.options.acceptor(obj) isnt true)

  isMatch = true
  util.traverse(attributes, (subpath, value) -> isMatch = false unless util.deepGet(record.options.attributes, subpath) is value) if attributes

  isMatch

# Export.
util.extend module.exports,
  Library: Library

