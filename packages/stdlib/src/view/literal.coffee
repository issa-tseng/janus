{ DomView, template, find, from } = require('janus')

$ = require('janus-dollar')

LiteralView = DomView.build($('<span class="janus-literal"/>'), template(
  find('span').text(from((subject) -> subject))
))

module.exports = {
  LiteralView,
  registerWith: (library) ->
    library.register(String, LiteralView)
    library.register(Number, LiteralView)
    library.register(Boolean, LiteralView)
}

