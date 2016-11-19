{ DomView, template, find, from } = require('janus')

$ = require('../util/dollar')

class LiteralView extends DomView
  @_dom: -> $('<span class="janus-literal"/>')
  @_template: template(find('span').text(from((subject) -> subject)))

module.exports = {
  LiteralView,
  registerWith: (library) ->
    library.register(String, LiteralView)
    library.register(Number, LiteralView)
    library.register(Boolean, LiteralView)
}

