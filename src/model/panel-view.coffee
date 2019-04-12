{ DomView, template, find, from } = require('janus')
{ InspectorView } = require('../common/inspector')
{ valuate } = require('../common/data-pair')
$ = require('janus-dollar')
{ KeyPair, WrappedModel } = require('./inspector')
{ inspect } = require('../inspect')

KeyPairView = DomView.build($('
  <div class="data-pair">
    <span class="pair-key"/>
    <span class="pair-delimeter"/>
    <span class="pair-value" title="Double-click to edit"/>
    <button class="pair-clear" title="Unset Value"/>
    <div class="pair-attribute">
      described by <span class="pair-attribute-entity"/>
    </div>
  </div>'), template(
  find('.data-pair')
    .classed('bound', from('bound'))
    .classed('primitive', from.vm('primitive'))

  find('.pair-key')
    .text(from('key'))
    .attr('title', from('key'))
  find('.pair-delimeter')
    .text(from('bound').map((b) -> if b is true then ' is bound to ' else ':'))
    .attr('title', from('bound').map((b) -> 'This value is bound' if b is true))
  find('.pair-value')
    .render(from('binding').and('value').all.map((b, v) -> inspect(b ? v)))
    .on('dblclick', (event, subject, view) ->
      event.preventDefault()
      type = if subject.get_('target').isModel then 'model' else 'map'
      valuate(type, subject, view)
    )

  find('.pair-attribute').classed('hide', from('attribute').map((x) -> !x?))
  find('.pair-attribute-entity').render(from('attribute').map(inspect))

  find('.pair-clear').on('click', (_, subject) ->
    subject.get_('target').unset(subject.get_('key')))
))

ModelPanelView = InspectorView.build($('
  <div class="janus-inspect-panel janus-inspect-model highlights">
    <div class="panel-title">
      <span class="model-type"/><span class="model-subtype"/>
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-content"/>
  </div>'), template(
  find('.model-type').text(from('type'))
  find('.model-subtype').text(from('subtype'))
  find('.panel-content').render(from.subject().map((mi) -> mi.pairsAll()))
))


module.exports = {
  KeyPairView, ModelPanelView
  registerWith: (library) ->
    library.register(KeyPair, KeyPairView)
    library.register(WrappedModel, ModelPanelView, context: 'panel')
}

