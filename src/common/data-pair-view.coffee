{ DomView, template, find, Model, attribute, bind, from } = require('janus')
{ isPrimitive, isArray, isFunction } = require('janus').util
{ DataPair } = require('./data-pair-model')
{ inspect } = require('../inspect')
$ = require('janus-dollar')

class DataPairVM extends Model.build(
    attribute('edit', attribute.Text)
    bind('primitive', from.subject('value').map(isPrimitive))
  )
  _initialize: ->
    app = this.get_('options.app')
    view = this.get_('view')
    subject = this.get_('subject')

    value = subject.get_('value')
    try
      this.set('edit', if isPrimitive(value) or isArray(value) then JSON.stringify(value) else '(…)')
    catch
      this.set('edit', '(…)')

    this.get('edit').react(false, (raw) =>
      expr = "return #{raw};"
      app = view.options.app
      try
        result =
          if isFunction(app.evaluate) then app.evaluate(expr)
          else (new Function(expr))()
        subject.get_('target').set(subject.get_('key'), result)
      catch ex
        app.flyout?(view.artifact(), ex)
    )

DataPairView = DomView.withOptions({ viewModelClass: DataPairVM }).build($('
    <div class="data-pair">
      <div class="pair-k">
        <span class="pair-key"/>
        <span class="pair-delimeter"/>
      </div>
      <div class="pair-v">
        <div class="pair-edit"></div>
        <span class="pair-value"></span>
        <button class="pair-clear" title="Unset Value"/>
      </div>
    </div>
  '), template(
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
      .render(from('binding').and('value')
        .all.map((b, v) -> inspect(b ? v)))
      .on('dblclick', (e, subject, { viewModel }, dom) ->
        return if subject.get_('bound') is true
        return unless viewModel.get_('primitive') is true
        dom.find('.pair-edit input').focus().select()
      )

    find('.pair-edit').render(from.vm().attribute('edit'))
      .criteria( context: 'edit', commit: 'hard' )

    find('.pair-clear').on('click', (_, subject) ->
      subject.get_('target').unset(subject.get_('key'))
    )
  )
)

module.exports = {
  DataPairVM
  DataPairView
  registerWith: (library) -> library.register(DataPair, DataPairView)
}

