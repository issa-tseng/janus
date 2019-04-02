{ min, max } = Math
{ DomView, template, find, from, Model, attribute, bind, dēfault } = require('janus')
$ = require('janus-dollar')
{ inspect } = require('../inspect')
{ ListInspector } = require('./inspector')
{ exists } = require('../util')

class ListEntityVM extends Model.build(
    dēfault('take', 5)
    bind('more_count', from.subject('length').and('take')
      .all.map((all, taken) -> max(0, all - taken)))
  )

  _initialize: ->
    this.set('take', 6) if this.get_('subject').get_('target').length_ is 6

ListEntityView = DomView.withOptions({ viewModelClass: ListEntityVM }).build($('
  <span class="janus-inspect-entity janus-inspect-list">
    <span class="entity-title"><span class="entity-type"/></span>
    <span class="entity-content">
      <span class="list-values"></span>
      <button class="entity-more list-more">&hellip;<span class="entity-more-count"/> more</button>
    </span>
  </span>'), template(

  find('.entity-type').text(from('type'))

  find('.list-values').render(from('target').and.vm('take').asVarying()
    .all.map((list, take) -> list.take(take).map(inspect)))

  find('.entity-more-count')
    .text(from.vm('more_count'))

  find('.entity-more')
    .classed('has-more', from.vm('more_count').map((x) -> x > 0))
    .on('click', (e, s, { viewModel }) ->
      taken = viewModel.get_('take')
      viewModel.set('take', taken + min(25, taken))
    )
))

module.exports = {
  ListEntityView,
  registerWith: (library) ->
    library.register(ListInspector, ListEntityView)
}

