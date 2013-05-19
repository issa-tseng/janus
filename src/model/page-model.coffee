util = require('../util/util')
Model = require('./model').Model

class PageModel extends Model
  render: ->
    # todo: what should this encapsulate?
    this._render()


util.extend(module.exports,
  PageModel: PageModel
)

