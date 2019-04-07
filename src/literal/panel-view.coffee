{ DomView, template, find, from } = require('janus')
{ ListPanelVM, moreButton } = require('../list/panel-view')
{ DataPair } = require('../common/data-pair-model')
{ ListForArray, ArrayEntityVM } = require('./entity-view')
{ ArrayInspector } = require('./inspector')
$ = require('janus-dollar')
{ inspect } = require('../inspect')


ArrayEntryView = DomView.build($('
  <div class="data-pair">
    <span class="pair-k"><span class="pair-key"/></span>
    <span class="pair-v"><span class="pair-value"/></span>
  </div>'), template(
  find('.pair-key').text(from('key'))
  find('.pair-value').render(from('value').map(inspect))
))


# TODO: ehhhh not the most graceful bit of code reuse ever.
class ArrayPanelVM extends ListPanelVM.ShowsLast.build(ListForArray)
  update: ArrayEntityVM.prototype.update

ArrayPanelView = DomView.withOptions({ viewModelClass: ArrayPanelVM }).build($('
  <div class="janus-inspect-panel janus-inspect-list">
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
      target.enumerate().take(take).map((key) -> new DataPair({ target, key }))
    )).options({ renderItem: (r) -> r.context('array-entry') })

  find('.list-last-item').render(from.vm('list').and('length')
    .all.map((target, length) -> new DataPair({ target, key: length - 1 })))

  moreButton
  find('.array-update').on('click', (e, s, { viewModel }) -> viewModel.update())
))


module.exports = {
  ArrayEntryView, ArrayPanelVM, ArrayPanelView
  registerWith: (library) ->
    library.register(DataPair, ArrayEntryView, context: 'array-entry')
    library.register(ArrayInspector, ArrayPanelView, context: 'panel')
}

