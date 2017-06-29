{ DomView, template, find, from, types } = require('janus')

$ = require('../util/dollar')

class SuccessResultView extends DomView
  @_dom: -> $('<div class="janus-successResult"/>')
  @_template: template(find('div').render(from.self().map((view) -> view.subject.value)))

module.exports = {
  SuccessResultView,
  registerWith: (library) -> library.register(types.result.success, SuccessResultView)
}

