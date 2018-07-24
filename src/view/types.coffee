{ DomView, template, find, from, types } = require('janus')

$ = require('janus-dollar')

SuccessResultView = DomView.build($('<div class="janus-successResult"/>'), template(
  find('div').render(from.self().map((view) -> view.subject.value))
))

module.exports = {
  SuccessResultView,
  registerWith: (library) -> library.register(types.result.success, SuccessResultView)
}

