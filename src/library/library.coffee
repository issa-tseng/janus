# The **Library** is a resource tracker. One can register classes or instances
# against it, and recall them via description. This enables flexibility around
# differing implementations of some functional task, such as rendering a model
# in a different context or making a semantically isomorphic network request
# from various environments, without being dependent on direct class reference.
#
# Note that in order to performantly track classtypes, registering a class with
# a library will result in a reference id being stored away upon it.

util = require('util')

class Library
  constructor: (@options = {}) ->
    this.shelf = {}

    this.options.handler ?= (obj, book) -> new book(obj)

  register: (klass, book, context = 'default', options = {}) ->
    bookId = Library._classId(klass)

    classShelf = this.shelf[bookId] ?= {}
    contextShelf = classShelf[context] ?= []

    contextShelf.push(
      book: book
      options: options
    )

    contextShelf.sort((a, b) -> (b.options.priority ? 0) - (a.options.priority ? 0)) if options.priority?

    book

  get: (obj, context = 'default', options = {}) ->
    result = this._get(obj, obj.constructor, context, options)
    this.options.handler(result) if result?

  _get: (obj, klass, context, options) ->
    klass = obj.constructor
    bookId = Library._classId(klass)
    contextShelf = this.shelf[bookId]?[context]

    if contextShelf?
      # we have a set of possible matches. go through them.
      return this.handler(record.book) for record in contextShelf when match(record, options)

    if klass.__super__?
      this._get(obj, klass.__super__.constructor, context, options)

  @classKey: "__janus_classId#{util.uniqueId()}"
  @classMap: {}

  @_classId: (klass) ->
    if klass[this.classKey]? and this.classMap[this.classKey] is klass
      klass[this.classKey]
    else
      id = util.uniqueId()
      this.classMap[id] = klass
      klass[this.classKey] = id

match = (record, options) ->
  return false unless record.options.rejector?(obj) isnt true
  return false if record.options.acceptor? and (record.options.acceptor(obj) isnt true)

  isMatch = true
  util.traverse(options.attributes, (subpath, value) -> isMatch = false unless util.deepGet(record.options.attributes, subpath) is value) if options.attributes

  isMatch

