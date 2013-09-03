
util = require('../util/util')
Model = require('../model/model').Model
attribute = require('../model/attribute')
List = require('./list').List
Varying = require('../core/varying').Varying

# Simple class for managing a paged look into a `LazyList`.
class Window extends Model
  @attribute 'page', class extends attribute.EnumAttribute
    values: -> this.model.watch('pageCount').map((count) -> new List([ 1..count ]))
    default: -> 1

  @bind('pageCount')
    .fromVarying(-> this.watch('parent').map((lazyList) -> lazyList.length()))
    .and('pageSize')
    .flatMap((total, pageSize) -> Math.ceil(total / pageSize))

  @bind('list').fromVarying ->
    range = null

    Varying.combine([
      this.watch('parent')
      this.watch('page')
      this.watch('pageSize')
    ], (parent, page, pageSize) =>
      range?.destroy()

      range =
        if parent? and page? and pageSize?
          parent.range(page * pageSize, page * pageSize + pageSize)
        else
          null
    )

util.extend(module.exports,
  Window: Window
)

