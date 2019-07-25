{ DomView, template, find, from, Model, attribute, bind, validate } = require('janus')
{ valid, error } = require('janus').types.validity
{ InspectorView } = require('../common/inspector')
{ tryValuate } = require('../common/valuate')
$ = require('janus-dollar')
{ KeyPair, WrappedModel } = require('./inspector')
{ inspect } = require('../inspect')
{ exists } = require('../util')


# little formview to name new pairs.
Namer = Model.build(
  attribute('name', class extends attribute.Text
    default: ->
      target = this.model.get_('target')
      i = 0
      ++i while target.get_(key = "untitled#{i}")?
      key
  )
  bind('name-exists', from('target').and('name')
    # TODO: i guess map needs a #has ?
    .all.flatMap((t, n) -> t.get(n).map(exists) if exists(n)))
  validate(from('name').map((n) -> if exists(n) then valid() else error()))
)
class NamerView extends DomView.build($('
  <div class="namer">
    <div class="namer-input"/>
    <div class="namer-warning">This key already exists!</div>
  </div>'), template(
  find('.namer-input').render(from.attribute('name')).criteria({ context: 'edit', commit: 'form' })
  find('.namer-warning').classed('hide', from('name-exists').map((x) -> !x))
))
  _wireEvents: -> this.artifact().find('input').focus().select()


KeyPairView = DomView.build($('
  <div class="data-pair">
    <span class="pair-key"/>
    <span class="pair-delimeter"/>
    <span class="pair-value"/>
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
    .attr('title', from('bound').map((b) -> 'Double-click to edit' unless b is true))
    .render(from('binding').and('value').all.map((b, v) -> inspect(b ? v)))
    .on('dblclick', tryValuate)

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
    <div class="panel-content">
      <div class="model-pairs"/>
      <button class="model-add" title="Add"/>
    </div>
  </div>'), template(
  find('.model-type').text(from('type'))
  find('.model-subtype').text(from('subtype'))
  find('.model-pairs').render(from.subject().map((mi) -> mi.pairsAll()))
  find('.model-add').on('click', (event, inspector, view) ->
    target = inspector.get_('target')
    values = [{ name: 'parent', value: target }]
    namer = new Namer({ target })
    namer.destroyWith(view)

    options = { title: 'Add Pair', values, rider: namer, focus: false }
    view.options.app.valuator($(event.target), options, (value) ->
      # the namer guarantees that the name exists so we just blindly take it.
      target.set(namer.get_('name'), value))
  )
))


module.exports = {
  KeyPairView, ModelPanelView
  registerWith: (library) ->
    library.register(Namer, NamerView)
    library.register(KeyPair, KeyPairView)
    library.register(WrappedModel, ModelPanelView, context: 'panel')
}

