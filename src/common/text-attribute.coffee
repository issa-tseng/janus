{ DomView, template, find, from, attribute } = require('janus')
$ = require('janus-dollar')

HardCommitTextView = DomView.build($('<input type="text"/>'), template(
  find('input')
    .prop('value', from((subject) -> subject.watchValue()))
    .on('keydown', (event, subject) ->
      input = $(event.target)
      if event.which is 13 # enter
        input.blur()
        subject.setValue(input.val())
      else if event.which is 27 # esc
        input.blur()
        input.val(subject.getValue())
    )
))

module.exports = {
  HardCommitTextView,
  registerWith: (library) -> library.register(attribute.Text, HardCommitTextView, context: 'edit', commit: 'hard')
}

