{ DomView, template, find, from, Model, bind } = require('janus')
{ InspectorView } = require('../../common/inspector')
$ = require('janus-dollar')
{ inspect } = require('../../inspect')
{ ListPanelVM, moreButton } = require('../panel-view')
{ ListInspector } = require('../inspector')
{ WrappedFunction } = require('../../function/inspector')
{ identity } = require('../../util')


class FilteredEntry extends Model.build(
  bind('parent.value', from('parent.list').and('index').all.flatMap((l, i) -> l.get(i)))
  bind('filter.varying', from('child.list').and('index').and('parent.value')
    .all.map((l, idx) -> l._filtereds[idx].parent))
  bind('filter.result', from('filter.varying').flatMap(identity))
  bind('filter.function', from('child.list').map((l) -> l.filterer)))

  constructor: (list, index) -> super({
    parent: { list: list.parent }
    child: { list }
    index
  })

FilteredEntryView = DomView.build($('
  <div class="data-pair">
    <span class="pair-key index-parent"/>
    <span class="pair-value value-parent"/>
    <span class="pair-function"/>
    <span class="filter-intermediate"/>
    <span class="filter-child-index"/>
  </div>'), template(
  find('.data-pair').classed('filter-pass', from('filter.result').map((x) -> x is true))

  find('.index-parent').text(from('index'))
  find('.value-parent').render(from('parent.value').map(inspect))

  find('.pair-function').on('mouseenter', (event, entry, view) ->
    return unless view.options.app.flyout?
    wf = new WrappedFunction(entry.get_('filter.function'), [ entry.get_('parent.value') ])
    view.options.app.flyout($(event.target), wf, context: 'panel')
  )

  find('.filter-intermediate').render(from('filter.varying').map(inspect))
))

# we have to use our parent's length to determine our length threshold.
FilteredListVM = ListPanelVM.build(
  bind('length', from.subject('target').flatMap((l) -> l.parent.length)))

FilteredListView = InspectorView.withOptions({ viewModelClass: FilteredListVM }).build($('
  <div class="janus-inspect-panel janus-inspect-list list-filtered highlights">
    <div class="panel-title">
      Filtered List
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-derivation">
      Filtered via <span class="list-filterer"/> from <span class="list-parent"/>
    </div>
    <div class="panel-content">
      <div class="list-list"/>
      <button class="list-more">&hellip; <span class="list-more-count"/> more</button>
    </div>
  </div>'), template(
  find('.list-filterer').render(from('target').map((list) -> inspect(list.filterer)))
  find('.list-parent').render(from('target').map((list) -> inspect(list.parent)))
  find('.list-list').render(from('target').and.vm('take.actual').asVarying().all.map((list, take) ->
    list.parent.enumerate().take(take).map((index) -> new FilteredEntry(list, index)))
  )

  moreButton
))

module.exports = {
  FilteredEntry, FilteredEntryView, FilteredListView
  registerWith: (library) ->
    library.register(FilteredEntry, FilteredEntryView)
    library.register(ListInspector.Filtered, FilteredListView, context: 'panel')
}

