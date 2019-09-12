{ DomView, template, find, from, Model, bind, initial } = require('janus')
{ InspectorView } = require('../common/inspector')
{ ListInspector } = require('./inspector')
$ = require('../dollar')
{ tryValuate } = require('../common/valuate')
{ inspect } = require('../inspect')
{ min, max } = Math


################################################################################
# LIST ENTRY VIEW

class ListEntry extends Model
ListEntryView = DomView.build($('
  <div class="data-pair">
    <button class="list-insert" title="Insert Item"/>
    <hr/>
    <span class="pair-key"/>
    <span class="pair-value" title="Double-click to edit"/>
    <button class="pair-clear" title="Unset Value"/>
  </div>'), template(
  find('.pair-key').text(from('key'))

  find('.pair-value')
    .render(from('target').and('key').all.flatMap((t, k) -> t.get(k).map(inspect)))
    .on('dblclick', tryValuate)

  find('.pair-clear').on('click', (_, subject) ->
    subject.get_('target').unset(subject.get_('key')))
))


################################################################################
# LIST PANEL VIEW

# TODO: a LOT of overlap with ListEntityVM
class ListPanelVM extends Model.build(
  bind('length', from.subject('target').flatMap((l) -> l.length))
  initial('take.setting', 10)
  bind('take.actual', from('take.setting').and('length').and('shows-last')
    .all.map((setting, length, showsLast) ->
      threshold = if showsLast is true then 2 else 1
      if setting + threshold >= length then length else setting
    ))
  bind('tail', from('length').and('take.actual').all.map((l, t) -> max(0, l - t)))
)
ListPanelVM.ShowsLast = ListPanelVM.build(
  initial('shows-last', true))

ListPanelView = InspectorView.build(ListPanelVM.ShowsLast, $('
  <div class="janus-inspect-panel janus-inspect-list highlights">
    <div class="panel-title">
      List
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-content">
      <div class="list-list"/>
      <button class="list-more">&hellip; <span class="list-more-count"/> more</button>
      <div class="list-last-item"/>
      <button class="list-insert list-insert-last" title="Insert Item"/>
    </div>
  </div>'), template(
  find('.janus-inspect-list')
    .classed('read-only', from.app().map((app) -> !(app.valuator?))
      .and('derived')
      .all.map((x, y) -> (x is true) or (y is true)))

  find('.list-list')
    .render(from('target').and.vm('take.actual').asVarying().all.map((target, take) ->
      target.enumerate().take(take).map((key) -> new ListEntry({ target, key }))
    ))

  template(
    'moreButton'
    find('.list-more-count').text(from.vm('tail').and.vm('shows-last')
      .all.map((x, showsLast) -> if showsLast is true then x - 1 else x))
    find('.list-more')
      .classed('has-more', from.vm('tail').map((t) -> t > 0))
      .on('click', (e, s, { viewModel }) ->
        taken = viewModel.get_('take.setting')
        viewModel.set('take.setting', taken + min(100, taken))
      )
  )

  find('.list-last-item').render(from('target').and.vm('length')
    .all.map((target, length) -> new ListEntry({ target, key: length - 1 })))

  find('.janus-inspect-list').on('click', '.list-insert', (event, subject, view) ->
    event.stopPropagation() # don't pop multiple up the stack
    target = $(event.target)
    return if target.hasClass('valuating')
    list = subject.get_('target')

    options = { title: 'Insert List Item', values: [{ name: 'list', value: list }] }
    valuator = view.options.app.valuator(target, options, ((result) ->
      idx =
        if target.hasClass('list-insert-last') then undefined
        else target.closest('.data-pair').prevAll().length
      list.add(result, idx)
    ))

    valuator.destroyWith(view)
    # TODO: less than elegant. i don't like direct stateful mutation.
    target.addClass('valuating')
    valuator.on('destroying', -> target.removeClass('valuating'))
  )
))


module.exports = {
  ListEntry, ListPanelVM, ListPanelView
  registerWith: (library) ->
    library.register(ListEntry, ListEntryView)
    library.register(ListInspector, ListPanelView, context: 'panel')
}

