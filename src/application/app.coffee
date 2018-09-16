{ Model } = require('../model/model')
{ attribute } = require('../model/schema')
attributes = require('../model/attribute')
{ Library } = require('./library')
{ Resolver } = require('../model/resolver')
{ isFunction, isArray } = require('../util/util')

class LibraryAttribute extends attributes.Attribute
  default: -> new Library()
  writeDefault: true

class App extends Model.build(
  attribute('views', LibraryAttribute)
  attribute('resolvers', LibraryAttribute))

  view: (subject, criteria = {}, options = {}) ->
    klass = this.get('views').get(subject, criteria)
    return unless klass?

    # instantiate result; autoinject ourself as app.
    view = new klass(subject, Object.assign({ app: this }, options))
    this.emit('createdView', view)

    # Handle reference resolution, both auto and manual.
    if subject?
      subject.autoResolveWith?(this)
      resolveSource = options.resolve ? view.resolve
      if resolveSource? and isFunction(subject.attribute)
        resolve = if isFunction(resolveSource) then resolveSource() else resolveSource
        keys = if isArray(resolve) then resolve else [ resolve ]
        for key in keys when (attribute = subject.attribute(key))?
          # we fire off an explicit resolve, in case auto was off. we also have
          # the view react on the key for its lifetime to ensure resolution.
          attribute.resolveWith(this) if attribute.isReference is true
          view.reactTo(subject.watch(key), (->)) if isFunction(subject.watch)

    view

  resolve: (request) ->
    result = (this._resolver$ ?= this.resolver())(request)
    this.emit('resolvedRequest', request, result) if result?
    result

  resolver: -> Resolver.fromLibrary(this.get('resolvers'))


module.exports = { App }

