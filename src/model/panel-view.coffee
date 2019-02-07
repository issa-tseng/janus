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
    bind('model', from('subject').get('model'))
  )
  _initialize: ->
    subject = this.get_('subject')
    do =>
      value = subject.get_('model').get_(subject.get_('key'))
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
      </div>
    </div>
  '), template(
    find('.kvPair').classed('bound', from('bound'))

    find('.kvPair-key')
      .text(from('key'))
      .attr('title', from('key'))

    find('.kvPair-value')
      .render(from('binding').and('subject').get('value').all.map((b, v) -> inspect(b ? v)))
      .on('dblclick', (event, _, __, dom) -> dom.find('.kvPair-edit input').focus().select())

    find('.kvPair-edit').render(from.attribute('edit')
        .and('subject').get('bound')
        .all.map((editor, bound) -> editor unless bound))
      .criteria( context: 'edit', commit: 'hard' )
  )
)


################################################################################
# PANEL VIEW

ModelPanelView = DomView.build($('
  <div class="janus-inspect-panel janus-inspect-model">
    <div class="panel-title"><span class="model-type"/><span class="model-subtype"/></div>
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

