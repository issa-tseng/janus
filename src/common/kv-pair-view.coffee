{ DomView, template, find, Model, attribute, bind, from } = require('janus')
{ isPrimitive, isArray } = require('janus').util
{ KVPair } = require('./kv-pair-model')
{ inspect } = require('../inspect')
$ = require('janus-dollar')

class KVPairVM extends Model.build(
    attribute('edit', attribute.Text)
    bind('key', from('subject').get('key'))
    bind('value', from('subject').get('value'))
    bind('primitive', from('value').map(isPrimitive))
    bind('target', from('subject').get('target'))
  )
  _initialize: ->
    app = this.get_('options.app')
    view = this.get_('view')
    subject = this.get_('subject')

    do =>
      value = this.get_('subject').get_('value')
      this.set('edit', if isPrimitive(value) or isArray(value) then JSON.stringify(value) else '(…)')

    this.get('edit').react(false, (raw) =>
      try
        result = (new Function("return #{raw};"))()
        subject.get_('target').set(subject.get_('key'), result)
      catch ex
        app.flyout?(view.artifact(), ex)
    )

KVPairView = DomView.withOptions({ viewModelClass: KVPairVM }).build($('
    <div class="janus-inspect-kvPair">
      <div class="kvPair-key"></div>
      <div class="kvPair-valueBlock">
        <div class="kvPair-edit"></div>
        <span class="kvPair-value"></span>
        <span class="kvPair-clear"></span>
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
      subject.get_('target').unset(subject.get_('key'))
    )
  )
)

module.exports = {
  KVPairVM
  KVPairView
  registerWith: (library) -> library.register(KVPair, KVPairView)
}

