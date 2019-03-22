{ DomView, template, find, from, Model, bind, dēfault } = require('janus')
{ ListInspector } = require('./inspector')
{ KVPair } = require('../common/kv-pair-model')
$ = require('janus-dollar')
{ inspect } = require('../inspect')
{ min, max } = Math


################################################################################
# LIST ENTRY VIEW

ListEntry = DomView.build($('
  <div class="list-entry">
    <button class="list-insert" title="Insert Item"/>
    <hr/>
    <div class="list-pair"/>
  </div>'), template(
  find('.list-pair').render(from.subject())
))


################################################################################
# LIST PANEL VIEW

# TODO: a LOT of overlap with ListEntityVM
class ListPanelVM extends Model.build(
  bind('length', from.subject('target').flatMap((l) -> l.length))
  dēfault('take.setting', 10)
  bind('take.actual', from('take.setting').and('length').and('shows-last')
    .all.map((setting, length, showsLast) ->
      threshold = if showsLast is true then 2 else 1
      if setting + threshold >= length then length else setting
    ))
  bind('tail', from('length').and('take.actual').all.map((l, t) -> max(0, l - t)))
)
ListPanelVM.ShowsLast = ListPanelVM.build(
  dēfault('shows-last', true))

moreButton = template(
  find('.list-more-count').text(from.vm('tail').and.vm('shows-last')
    .all.map((x, showsLast) -> if showsLast is true then x - 1 else x))
  find('.list-more')
    .classed('has-more', from.vm('tail').map((t) -> t > 0))
    .on('click', (e, s, { viewModel }) ->
      taken = viewModel.get_('take.setting')
      viewModel.set('take.setting', taken + min(100, taken))
    )
)

ListPanelView = DomView.withOptions({ viewModelClass: ListPanelVM.ShowsLast }).build($('
  <div class="janus-inspect-panel janus-inspect-list">
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
    .classed('read-only', from.app().map((app) -> !(app.popValuator?))
      .and('derived')
      .all.map((x, y) -> (x is true) or (y is true)))

  find('.list-list')
    .render(from('target').and.vm('take.actual').asVarying().all.map((target, take) ->
      target.enumerate().take(take).map((key) -> new KVPair({ target, key }))
    ))
    .options({ renderItem: (r) -> r.context('list-entry') })

  moreButton

  find('.list-last-item').render(from('target').and.vm('length')
    .all.map((target, length) -> new KVPair({ target, key: length - 1 })))

  find('.janus-inspect-list').on('click', '.list-insert', (event, subject, view) ->
    event.stopPropagation() # don't pop multiple up the stack
    target = $(event.target)
    return if target.hasClass('valuating')
    # TODO: don't put strings here:
    valuator = view.options.app.popValuator('Insert List Item', (result) ->
      idx =
        if target.hasClass('list-insert-last') then undefined
        else target.closest('li').prevAll().length
      subject.get_('target').add(result, idx)
    )

    # TODO: less than elegant. i don't like direct stateful mutation.
    target.addClass('valuating')
    valuator.on('destroying', -> target.removeClass('valuating'))
  )
))


module.exports = {
  moreButton
  ListEntry, ListPanelVM, ListPanelView
  registerWith: (library) ->
    library.register(KVPair, ListEntry, context: 'list-entry')
    library.register(ListInspector, ListPanelView, context: 'panel')
}

