{ Model } = require('../model/model')
{ attribute } = require('../model/schema')
attributes = require('../model/attribute')
{ Library } = require('./library')
{ Resolver } = require('../model/resolver')
{ isFunction, isArray } = require('../util/util')

class LibraryAttribute extends attributes.Attribute
  initial: -> new Library()
  writeInitial: true

class App extends Model.build(
  attribute('views', LibraryAttribute)
  attribute('resolvers', LibraryAttribute))

  Object.defineProperty(@prototype, 'views', get: -> this.get_('views'))
  Object.defineProperty(@prototype, 'resolvers', get: -> this.get_('resolvers'))

  view: (subject, criteria = {}, options = {}, parent) ->
    klass = this.get_('views').get(subject, criteria)
    return unless klass?

    # instantiate result; autoinject ourself as app.
    view = new klass(subject, Object.assign({ app: this, parent }, options))
    this.emit('createdView', view)

    # autoresolution of Reference attributes:
    if (attrs = subject?.attributes?())
      for attr in attrs when attr.isReference is true and attr.autoResolve is true
        attr.resolveWith(this)

    view

  resolve: (request) ->
    result = (this._resolver$ ?= this.resolver())(request)
    this.emit('resolvedRequest', request, result) if result?
    result

  resolver: -> Resolver.fromLibrary(this.get_('resolvers'))


module.exports = { App }

