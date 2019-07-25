{ template, find, from } = require('janus')
{ InspectorView } = require('../common/inspector')
$ = require('janus-dollar')
{ tryValuate } = require('../common/valuate')
{ inspect } = require('../inspect')
{ WrappedVarying } = require('./inspector')

VaryingEntityView = InspectorView.build($('
  <span class="janus-inspect-entity janus-inspect-varying highlights">
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

    .on('click', (_, subject) -> subject.varying.react(->))

  find('.varying-value').render(from('value').and('immediate')
    .all.map((value, immediate) => inspect(value ? immediate)))

  find('.entity-content')
    .attr('title', from('derived').map((d) -> 'Double-click to edit' unless d is true))
    .on('dblclick', tryValuate)
))

module.exports = {
  VaryingEntityView,
  registerWith: (library) ->
    library.register(WrappedVarying, VaryingEntityView)
}

