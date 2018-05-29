{ Varying, DomView, template, find, from } = require('janus')

$ = require('../util/dollar')

VaryingView = DomView.build($('<div class="janus-varying"/>'), template(
  find('div').render(from((subject) -> subject))
    .context(from.self((view) -> view.options.libraryContext ? 'default'))
))

module.exports = { VaryingView, registerWith: (library) -> library.register(Varying, VaryingView) }

