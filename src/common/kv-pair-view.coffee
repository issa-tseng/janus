{ DomView, template, find, Model, attribute, bind, from } = require('janus')
{ isPrimitive, isArray } = require('janus').util
{ KVPair } = require('./kv-pair-model')
{ inspect } = require('../inspect')
$ = require('janus-dollar')

class KVPairVM extends Model.build(
    attribute('edit', attribute.Text)
    bind('primitive', from.subject('value').map(isPrimitive))
  )
  _initialize: ->
    app = this.get_('options.app')
    view = this.get_('view')
    subject = this.get_('subject')

    do =>
      value = subject.get_('value')
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
        <button class="kvPair-clear" title="Unset Value"/>
      </div>
    </div>
  '), template(
    find('.janus-inspect-kvPair')
      .classed('bound', from('bound'))
      .classed('primitive', from.vm('primitive'))

    find('.kvPair-key')
      .text(from('key'))
      .attr('title', from('key'))

    find('.kvPair-value')
      .render(from('subject').get('binding').and('value')
        .all.map((b, v) -> inspect(b ? v)))
      .on('dblclick', (e, subject, { viewModel }, dom) ->
        return if subject.get_('bound') is true
        return unless viewModel.get_('primitive') is true
        dom.find('.kvPair-edit input').focus().select()
      )

    find('.kvPair-edit').render(from.vm().attribute('edit'))
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

