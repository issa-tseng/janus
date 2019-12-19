{ DomView, template, find, from, Model, bind } = require('janus')
{ InspectorView } = require('../../common/inspector')
$ = require('../../dollar')
{ inspect } = require('../../inspect')
{ ListPanelVM, ListPanelView } = require('../panel-view')
{ ListInspector } = require('../inspector')
{ WrappedFunction } = require('../../function/inspector')
{ MappedEntry } = require('./mapped-list')


class FlatMappedEntry extends MappedEntry.build(
  bind('child.value', from('child.list').and('index').all.flatMap((l, i) ->
    l._bindings.get(i).map((o) -> o.parent))) # TODO: silly
)

FlatMappedListView = InspectorView.build(ListPanelVM.ShowsLast, $('
  <div class="janus-inspect-panel janus-inspect-list list-mapped highlights">
    <div class="panel-title">
      FlatMapped List
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
    list.enumerate().take(take).map((index) -> new FlatMappedEntry(list, index)))
  )
  find('.list-last-item').render(from('target').map((list) -> new FlatMappedEntry(list, -1)))

  ListPanelView.template.moreButton
))

module.exports = {
  FlatMappedEntry, FlatMappedListView
  registerWith: (library) ->
    library.register(ListInspector.FlatMapped, FlatMappedListView, context: 'panel')
}


