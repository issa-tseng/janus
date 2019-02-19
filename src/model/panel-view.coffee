{ DomView, template, find, from, Model, attribute, bind } = require('janus')
{ isPrimitive, isArray } = require('janus').util
$ = require('janus-dollar')
{ inspect } = require('../inspect')
{ WrappedModel, KVPair } = require('./inspector')


################################################################################
# KEY/VALUE PAIR

class KVPairVM extends Model.build(
    attribute('edit', attribute.Text)
    bind('key', from('subject').get('key'))
    bind('value', from('subject').get('value'))
    bind('primitive', from('value').map(isPrimitive))
    bind('model', from('subject').get('model'))
  )
  _initialize: ->
    app = this.get_('options.app')
    view = this.get_('view')
    subject = this.get_('subject')

    do =>
      value = this.get_('subject').get_('value')
      this.set('edit', if isPrimitive(value) or isArray(value) then JSON.stringify(value) else '…')

    this.get('edit').react(false, (raw) =>
      try
        result = (new Function("return #{raw};"))()
        subject.get_('model').set(subject.get_('key'), result)
      catch ex
        console.log("that didn't work..", ex) # TODO: surface this more usefully
    )

KVPairView = DomView.withOptions({ viewModelClass: KVPairVM }).build($('
    <div class="janus-inspect-kvPair">
      <div class="kvPair-key"></div>
      <div class="kvPair-valueBlock">
        <div class="kvPair-value"></div>
        <div class="kvPair-edit"></div>
        <div class="kvPair-clear"></div>
      </div>
    </div>
  '), template(
    find('.janus-inspect-kvPair')
      .classed('bound', from('subject').get('bound'))
      .classed('primitive', from('primitive'))

    find('.kvPair-key')
      .text(from('key'))
      .attr('title', from('key'))

    find('.kvPair-value')
      .render(from('subject').get('binding').and('value')
        .all.map((b, v) -> inspect(b ? v)))
      .on('dblclick', (e, subject, v, dom) ->
        return if subject.get_('subject').get_('bound') is true
        return unless subject.get_('primitive') is true
        dom.find('.kvPair-edit input').focus().select()
      )

    find('.kvPair-edit').render(from.attribute('edit'))
      .criteria( context: 'edit', commit: 'hard' )

    find('.kvPair-clear').on('click', (_, subject) ->
      subject.get_('model').unset(subject.get_('key'))
    )
  )
)


################################################################################
# PANEL VIEW

ModelPanelView = DomView.build($('
  <div class="janus-inspect-panel janus-inspect-model">
    <div class="panel-title">
      <span class="model-type"/><span class="model-subtype"/>
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-content"/>
  </div>'), template(
    find('.model-type').text(from('type'))
    find('.model-subtype').text(from('subtype'))
    find('.panel-content').render(from('pairs'))
))


module.exports = {
  KVPairVM, KVPairView, ModelPanelView
  registerWith: (library) ->
    library.register(KVPair, KVPairView)
    library.register(WrappedModel, ModelPanelView, context: 'panel')
}

