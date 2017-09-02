Model = require('../model/model').Model
attribute = require('../model/attribute')
List = require('../collection/list').List
util = require('../util/util')


class App extends Model
  @default('stack', new List(), attribute.CollectionAttribute)

  vend: (type, obj, options = {}) ->
    library = this.get(type)
    return unless library?.isLibrary is true

    app = this.with( stack: new List(this.get('stack').list.concat([ obj ])) )
    result = library.get(obj, util.extendNew(options, { constructorOpts: util.extendNew(options.constructorOpts, { app }) }))

    this.emit('vended', type, result) if result?
    result

  vendView: (obj, options) -> this.vend('views', obj, options)
  vendStore: (obj, options) -> this.vend('stores', obj, options)

  stack: -> this.get('stack').shadow()

  resolve: (key) -> super(key, this)


module.exports = { App }

