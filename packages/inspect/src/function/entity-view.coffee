{ DomView, template, find, from } = require('janus')
{ InspectorView } = require('../common/inspector')
$ = require('janus-dollar')
{ Applicant, WrappedFunction } = require('./inspector')
{ exists } = require('../util')
{ inspect } = require('../inspect')


ApplicantView = DomView.build($('
  <span class="janus-inspect-applicant"><span class="applicant-name"/><span class="applicant-value"/></span>
'), template(
  find('.janus-inspect-applicant').classed('has-value', from('value').map((x) -> x?)),
  find('.applicant-name').text(from('name')),
  find('.applicant-value').render(from('value').map((v) -> inspect(v) if v?))
))

FunctionEntityView = InspectorView.build($('
  <span class="janus-inspect-entity janus-inspect-function highlights">
    <span class="entity-title">Function</span>
    <span class="entity-content">
      <span class="function-name"/>(<span class="function-args"/>)</span>
    </span>
  </span>'), template(

  find('.function-name').text(from('target').map((f) -> if exists(f.name) then f.name else 'λ'))
  find('.function-args').render(from('arg.pairs'))
))

module.exports = {
  ApplicantView,
  FunctionEntityView,
  registerWith: (library) ->
    library.register(Applicant, ApplicantView)
    library.register(WrappedFunction, FunctionEntityView)
}

