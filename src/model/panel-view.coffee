{ DomView, template, find, from, Model, attribute } = require('janus')
{ InspectorView } = require('../common/inspector')
{ tryValuate } = require('../common/valuate')
$ = require('janus-dollar')
{ KeyPair, WrappedModel } = require('./inspector')
{ inspect } = require('../inspect')
{ exists } = require('../util')


################################################################################
# MODEL NEW-PAIR FORM
# TODO: because of our shortcut of using the popup valuator but not putting the attr key
# declaration also in the popup, everything about this is really quite ramshackle:
# 1. tab inputs from attr key do not go to the valuator
# 2. pressing enter on just the attr key does nothing
# 3. the valuator is the wrong width
# 4. it just feels lame
# fix it someday not forever from now.

class NewPair extends Model.build(
  attribute('key', attribute.Text)
)
  _initialize: ->
    model = this.get_('target')
    i = 0
    false while model.get_(key = "untitled#{++i}")
    this.set('key', key)

class NewPairView extends DomView.build($('
  <div class="new-pair">
    <div class="new-key"/>
    <div class="new-value"/>
    <button class="new-create" title="Create"/>
  </div>'), template(
  find('.new-key').render(from.attribute('key')).context('edit')
  find('.new-value').render(from('value').map(inspect))
  find('.new-create').on('click', (e, s, view) -> view.tryCommit())
))
  _wireEvents: ->
    dom = this.artifact()
    subject = this.subject
    options = { title: 'New Value', values: [{ name: 'parent', value: subject.get_('target') }] }

    this.options.app.valuator(dom.find('.new-key'), options, (value) =>
      subject.set('value', value)
      subject.set('value-set', true) # we do this separately so you can set null/undef if you want.
      this.tryCommit()
    )
    this.destroyWith(subject)

    # the valuator will try to set focus on the value. we want to set it back on the key.
    dom.find('.new-key input').focus().select()
    return


  tryCommit: ->
    subject = this.subject
    return unless subject.get_('value-set') is true
    return unless exists(key = subject.get_('key')?.trim())
    # TODO: warn if overwriting a key.
    value = subject.get_('value')
    subject.get_('target').set(key, value)
    subject.destroy()


################################################################################
# KEYPAIR / MODEL VIEWS

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

class ModelVM extends Model
  _initialize: ->
    this.reactTo(this.get('create'), false, (c) => c?.on('destroying', => this.unset('create')))

ModelPanelView = InspectorView.withOptions({ viewModelClass: ModelVM }).build($('
  <div class="janus-inspect-panel janus-inspect-model highlights">
    <div class="panel-title">
      <span class="model-type"/><span class="model-subtype"/>
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-content">
      <div class="model-pairs"/>
      <div class="model-create"/>
      <button class="model-do-create" title="Add New"/>
    </div>
  </div>'), template(
  find('.model-type').text(from('type'))
  find('.model-subtype').text(from('subtype'))
  find('.model-pairs').render(from.subject().map((mi) -> mi.pairsAll()))

  find('.model-create')
    .classed('creating', from.vm('create').map(exists))
    .render(from.vm('create'))
  find('.model-do-create') .on('click', (e, inspector, { vm }) ->
    vm.set('create', new NewPair({ target: inspector.get_('target') })))
))


module.exports = {
  KeyPairView, ModelPanelView
  registerWith: (library) ->
    library.register(NewPair, NewPairView)
    library.register(KeyPair, KeyPairView)
    library.register(WrappedModel, ModelPanelView, context: 'panel')
}

