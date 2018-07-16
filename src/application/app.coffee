{ Model } = require('../model/model')
{ dfault } = require('../model/schema')
{ Library } = require('./library')
{ Resolver } = require('../model/resolver')
{ isFunction, isArray } = require('../util/util')


App = class extends Model.build(
  dfault('views', -> new Library())
  dfault('resolvers', -> new Library()))

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
        attrs = if isArray(resolve) then resolve else [ resolve ]
        for key in attrs when (attribute = subject.attribute(key))?
          attribute.resolveWith(this) if attribute.isReference is true

    view

  resolve: (request) ->
    return unless request?.isRequest is true
    result = (this._resolver$ ?= this.resolver())(request)
    this.emit('resolvedRequest', result) if result?
    result

  resolver: -> Resolver.fromLibrary(this.get('resolvers'))


module.exports = { App }

