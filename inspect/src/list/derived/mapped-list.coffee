{ DomView, template, find, from, Model, bind } = require('janus')
{ InspectorView } = require('../../common/inspector')
$ = require('../../dollar')
{ inspect } = require('../../inspect')
{ ListPanelVM, moreButton } = require('../panel-view')
{ ListInspector } = require('../inspector')
{ WrappedFunction } = require('../../function/inspector')


class MappedEntry extends Model.build(
  bind('parent.list', from('child.list').map((c) -> c.parent))
  bind('parent.value', from('parent.list').and('index').all.flatMap((l, i) -> l.get(i)))
  bind('child.value', from('child.list').and('index').all.flatMap((l, i) -> l.get(i))))
  constructor: (child, index) -> super({ child: { list: child }, index })


MappedEntryView = DomView.build($('
  <div class="data-pair">
    <span class="pair-key"/>
    <span class="pair-value value-parent"/>
    <span class="pair-function"/>
    <span class="pair-value value-child"/>
  </div>'), template(
  find('.pair-key').text(from('parent.list').and('index').all.flatMap((list, index) ->
    if index is -1 then list.length.map((x) -> x - 1)
    else index
  ))

  find('.value-parent').render(from('parent.value').map(inspect))
  find('.value-child').render(from('child.value').map(inspect))

  find('.pair-function').on('mouseenter', (event, entry, view) ->
    return unless view.options.app.flyout?
    wf = new WrappedFunction(entry.get_('child.list').mapper, [ entry.get_('parent.value') ])
    view.options.app.flyout($(event.target), wf, context: 'panel')
  )
))

MappedListView = InspectorView.withOptions({ viewModelClass: ListPanelVM.ShowsLast }).build($('
  <div class="janus-inspect-panel janus-inspect-list list-mapped highlights">
    <div class="panel-title">
      Mapped List
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-derivation">
      Mapped via <span class="list-mapper"/> from <span class="list-parent"/>
    </div>
    <div class="panel-content">
      <div class="list-list"/>
      <button class="list-more">&hellip; <span class="list-more-count"/> more</button>
      <div class="list-last-item"/>
    </div>
  </div>'), template(
  find('.list-mapper').render(from('target').map((list) -> inspect(list.mapper)))
  find('.list-parent').render(from('target').map((list) -> inspect(list.parent)))

  find('.list-list').render(from('target').and.vm('take.actual').asVarying().all.map((list, take) ->
    list.enumerate().take(take).map((index) -> new MappedEntry(list, index)))
  )
  find('.list-last-item').render(from('target').map((list) -> new MappedEntry(list, -1)))

  moreButton
))

module.exports = {
  MappedEntry, MappedEntryView, MappedListView
  registerWith: (library) ->
    library.register(MappedEntry, MappedEntryView)
    library.register(ListInspector.Mapped, MappedListView, context: 'panel')
}

