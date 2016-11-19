{ Varying, DomView, template, find, from } = require('janus')

$ = require('../util/dollar')

class VaryingView extends DomView
  @_dom: -> $('<div class="janus-varying"/>')
  @_template: template(
    find('div').render(from((subject) -> subject))
      .context(from.self((view) -> view.options.libraryContext ? 'default'))
  )

module.exports = { VaryingView, registerWith: (library) -> library.register(Varying, VaryingView) }

