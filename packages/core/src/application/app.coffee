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

    # Handle reference resolution, both auto and manual.
    if subject?
      # autoresolution of Reference attributes:
      if (attrs = subject.attributes?())
        for attr in attrs when attr.isReference is true and attr.autoResolve is true
          attr.resolveWith(this)

      # manual resolution as specified in options/view properties:
      resolveSource = options.resolve ? view.resolve
      if resolveSource? and isFunction(subject.attribute)
        resolve = if isFunction(resolveSource) then resolveSource() else resolveSource
        keys = if isArray(resolve) then resolve else [ resolve ]
        for key in keys when (attribute = subject.attribute(key))?
          # we fire off an explicit resolve, in case auto was off. we also have
          # the view react on the key for its lifetime to ensure resolution.
          attribute.resolveWith(this) if attribute.isReference is true
          view.reactTo(subject.get(key), (->)) if isFunction(subject.get)

    view

  resolve: (request) ->
    result = (this._resolver$ ?= this.resolver())(request)
    this.emit('resolvedRequest', request, result) if result?
    result

  resolver: -> Resolver.fromLibrary(this.get_('resolvers'))


module.exports = { App }

