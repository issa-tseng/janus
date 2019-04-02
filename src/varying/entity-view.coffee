{ DomView, template, find, from } = require('janus')
$ = require('janus-dollar')
{ inspect } = require('../inspect')
{ WrappedVarying } = require('./inspector')

VaryingEntityView = DomView.build($('
  <span class="janus-inspect-entity janus-inspect-varying">
    <span class="entity-title">Varying</span>
    <span class="entity-content">
      <span class="varying-unknown" title="No observers, so no value. Click to force.">�</span>
      <span class="varying-value"></span>
    </span>
  </span>'), template(

  find('.varying-unknown')
    .classed('unknown', from('observations').flatMap((os) -> os.length)
      .and('derived')
      .all.map((ol, derived) -> (ol is 0) and derived))

    # TODO: cancellable?
    .on('click', (_, subject) -> subject.varying.react(->))

  find('.varying-value').render(from('value').and('immediate')
    .all.map((value, immediate) => inspect(value ? immediate)))

  #.criteria( context: 'inspect', style: 'entity' ),
  #find('.varying-rxn-count').text(from('reactions').flatMap((rxns) -> rxns.watchLength()))
))

module.exports = {
  VaryingEntityView,
  registerWith: (library) ->
    library.register(WrappedVarying, VaryingEntityView)
}

