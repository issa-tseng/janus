{ Model, DomView, template, find, from } = require('janus')
{ InspectorView } = require('../common/inspector')
{ ListPanelVM, ListPanelView } = require('../list/panel-view')
{ ListForArray, ArrayEntityVM } = require('./entity-view')
{ ArrayInspector } = require('./inspector')
$ = require('../dollar')
{ inspect } = require('../inspect')

class ArrayEntry extends Model
ArrayEntryView = DomView.build($('
  <div class="data-pair">
    <span class="pair-key"/>
    <span class="pair-value"/>
  </div>'), template(
  find('.pair-key').text(from('key'))
  find('.pair-value').render(from('target').and('key').all.flatMap((t, k) ->
    t.get(k).map(inspect)))
))


# TODO: ehhhh not the most graceful bit of code reuse ever.
class ArrayPanelVM extends ListPanelVM.ShowsLast.build(ListForArray)
  update: ArrayEntityVM.prototype.update

ArrayPanelView = InspectorView.withOptions({ viewModelClass: ArrayPanelVM }).build($('
  <div class="janus-inspect-panel janus-inspect-list highlights">
    <div class="panel-title">
      Array
      <button class="array-update" title="Update"/>
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-content">
      <div class="list-list"/>
      <button class="list-more">&hellip; <span class="list-more-count"/> more</button>
      <div class="list-last-item"/>
    </div>
  </div>'), template(
  find('.list-list')
    .render(from.vm('list').and.vm('take.actual').asVarying().all.map((target, take) ->
      target.enumerate().take(take).map((key) -> new ArrayEntry({ target, key }))
    ))

  find('.list-last-item').render(from.vm('list').and('length')
    .all.map((target, length) -> new ArrayEntry({ target, key: length - 1 })))

  ListPanelView.template.moreButton
  find('.array-update').on('click', (e, s, { viewModel }) -> viewModel.update())
))


module.exports = {
  ArrayEntryView, ArrayPanelVM, ArrayPanelView
  registerWith: (library) ->
    library.register(ArrayEntry, ArrayEntryView)
    library.register(ArrayInspector, ArrayPanelView, context: 'panel')
}

