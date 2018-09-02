{ DomView, template, find, from } = require('janus')
$ = require('janus-dollar')
{ inspect } = require('../inspect')
{ WrappedVarying } = require('./inspector')

VaryingEntityView = DomView.build($('
  <div class="janus-inspect-entity janus-inspect-varying">
    <span class="entity-title">Varying</span>
    <span class="entity-content">
      <span class="varying-value"></span>
    </span>
  </div>'), template(

  find('.varying-value').render(from('value').and('immediate')
    .all.map((value, immediate) => inspect(value || immediate)))

  #.criteria( context: 'inspect', style: 'entity' ),
  #find('.varying-rxn-count').text(from('reactions').flatMap((rxns) -> rxns.watchLength()))
))

module.exports = {
  VaryingEntityView,
  registerWith: (library) ->
    library.register(WrappedVarying, VaryingEntityView)
}

