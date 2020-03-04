{ DomView, template, find, from, Model, attribute, bind, validate } = require('janus')
{ valid, error } = require('janus').types.validity
{ InspectorView } = require('../common/inspector')
{ reference } = require('../common/types')
{ tryValuate } = require('../common/valuate')
$ = require('../dollar')
{ KeyPair, MappedKeyPair, ModelInspector } = require('./inspector')
{ WrappedFunction } = require('../function/inspector')
{ FlatMappedEntry } = require('../list/derived/flatmapped-list')
{ inspect } = require('../inspect')
{ exists } = require('../util')


# little formview to name new pairs.
Namer = Model.build(
  attribute('name', class extends attribute.Text
    initial: ->
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
      .options(from.self().and('key').all.map((view, k) ->
        { __source: view.closest_(ModelPanelView), __ref: reference.get(k) }))
    .on('dblclick', tryValuate)

  find('.pair-attribute').classed('hide', from('attribute').map((x) -> !x?))
  find('.pair-attribute-entity').render(from('attribute').map(inspect))
    .options(from.self().and('key').all.map((view, k) ->
      { __source: view.closest_(ModelPanelView), __ref: reference.attr(k) }))

  find('.pair-clear').on('click', (_, subject) ->
    subject.get_('target').unset(subject.get_('key')))
))

MappedKeyPairView = DomView.build($('
  <div class="data-pair">
    <span class="pair-key"/>
    <span class="pair-delimeter"/>
    <span class="value-parent"/>
    <span class="pair-function"/>
    <span class="pair-value value-child"/>
  </div>'), template(
  KeyPairView.template,
  find('.value-parent').render(from('parent-value').map(inspect))
    .options(from.self().and('key').all.map((__source, k) ->
      { __source, __ref: [ reference.parent(), reference.get(k) ] }))
  find('.pair-function').on('mouseenter', (event, pair, view) ->
    return unless view.options.app.flyout?
    wf = new WrappedFunction(pair.get_('mapper'), [ pair.get_('key'), pair.get_('parent-value') ])
    view.options.app.flyout($(event.target), wf, context: 'panel')
  )
))

ModelPanelView = InspectorView.build($('
  <div class="janus-inspect-panel janus-inspect-model highlights">
    <div class="panel-title">
      <span class="model-type"/><span class="model-subtype"/>
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-derivation">
      <span class="model-relationship"/> from <span class="model-parent"/>
    </div>
    <div class="panel-content">
      <div class="model-pairs"/>
      <button class="model-add" title="Add"/>
      <div class="model-validation">
        <label>Model Validations</label>
        <div class="model-validations"/>
      </div>
    </div>
  </div>'), template(
  find('.model-type').text(from('type'))
  find('.model-subtype').text(from('subtype'))
  find('.panel-derivation').classed('hide', from('parent').map((x) -> !x?))
  find('.model-relationship').text(from.subject().map((i) ->
    if i.isTargetDerived is true then 'Mapped' else 'Shadowed'))
  find('.model-parent').render(from('parent').map(inspect))
    .options(from.self().map((__source) -> { __source, __ref: reference.parent() }))
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

  find('.model-validation').classed('hide', from('validations').flatMap((vs) -> vs.empty()))
  find('.model-validations').render(from('validations').map((vs) ->
    vs.enumerate().map((index) -> new FlatMappedEntry(vs, index))))
))


module.exports = {
  KeyPairView, ModelPanelView
  registerWith: (library) ->
    library.register(Namer, NamerView)
    library.register(KeyPair, KeyPairView)
    library.register(MappedKeyPair, MappedKeyPairView)
    library.register(ModelInspector, ModelPanelView, context: 'panel')
}

