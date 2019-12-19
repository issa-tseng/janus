{ DomView, template, find, from, Model, bind, initial } = require('janus')
{ InspectorView } = require('../common/inspector')
{ SetInspector } = require('./inspector')
$ = require('../dollar')
{ tryValuate } = require('../common/valuate')
{ inspect } = require('../inspect')
{ ListPanelVM, ListPanelView } = require('../list/panel-view')

class SetEntry extends Model
SetEntryView = DomView.build($('
  <div class="data-pair">
    <span class="pair-value"/>
    <button class="pair-clear" title="Delete Value"/>
  </div>'), template(
  find('.pair-value').render(from('value').map(inspect))
  find('.pair-clear').on('click', (_, subject) ->
    subject.get_('target').remove(subject.get_('value')))
))

SetPanelView = InspectorView.build(ListPanelVM, $('
  <div class="janus-inspect-panel janus-inspect-list highlights">
    <div class="panel-title">
      Set
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-content">
      <div class="list-list"/>
      <button class="list-more">&hellip; <span class="list-more-count"/> more</button>
      <button class="list-insert list-insert-last" title="Insert Item"/>
    </div>
  </div>'), template(
  find('.list-list')
    .render(from('target').and.vm('take.actual').asVarying().all.map((target, take) ->
      target._list.take(take).map((value) -> new SetEntry({ target, value }))))

  ListPanelView.template.moreButton

  # TODO: repetitive from list panel
  find('.list-insert').on('click', (event, subject, view) ->
    event.stopPropagation()
    target = $(event.target)
    return if target.hasClass('valuating')
    set = subject.get_('target')

    options = { title: 'Add Set Item', values: [{ name: 'set', value: set }] }
    valuator = view.options.app.valuator(target, options, ((result) -> set.add(result)))
    valuator.destroyWith(view)

    target.addClass('valuating')
    valuator.on('destroying', -> target.removeClass('valuating'))
  )
))

module.exports = {
  SetEntry, SetPanelView
  registerWith: (library) ->
    library.register(SetEntry, SetEntryView)
    library.register(SetInspector, SetPanelView, context: 'panel')
}

