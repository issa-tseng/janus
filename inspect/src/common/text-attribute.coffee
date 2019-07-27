{ DomView, template, find, from, attribute } = require('janus')
$ = require('../dollar')

FormCommitTextView = DomView.build($('<input type="text" spellcheck="false"/>'), template(
  find('input')
    .prop('value', from((subject) -> subject.getValue()))
    .on('change', (event, subject, view) -> subject.setValue(view.artifact().val()))
))

module.exports = {
  FormCommitTextView,
  registerWith: (library) -> library.register(attribute.Text, FormCommitTextView, context: 'edit', commit: 'form')
}

