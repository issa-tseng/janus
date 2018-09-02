{ DomView, template, find, from, Model, attribute, bind } = require('janus')
{ isPrimitive, isArray } = require('janus').util
$ = require('janus-dollar')
{ inspect } = require('../inspect')
{ WrappedModel, KVPair } = require('./inspector')


################################################################################
# KEY/VALUE PAIR

class KVPairVM extends Model.build(
    attribute('edit', attribute.Text)
    bind('key', from('subject').watch('key'))
    bind('model', from('subject').watch('model'))
  )
  _initialize: ->
    subject = this.get('subject')
    do =>
      value = subject.get('model').get(subject.get('key'))
      this.set('edit', if isPrimitive(value) or isArray(value) then JSON.stringify(value) else '…')

    this.watch('edit').react(false, (raw) =>
      try
        result = (new Function("return #{raw};"))()
        subject.get('model').set(subject.get('key'), result)
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
      .render(from('binding').and('subject').watch('value').all.map((b, v) -> inspect(b ? v)))
      .on('dblclick', (event, _, __, dom) -> dom.find('.kvPair-edit input').focus().select())

    find('.kvPair-edit').render(from.attribute('edit')
        .and('subject').watch('bound')
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

