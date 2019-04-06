{ min, max } = Math
{ DomView, template, find, from, Model, attribute, bind, dēfault } = require('janus')
$ = require('janus-dollar')
{ inspect } = require('../inspect')
{ ListInspector } = require('./inspector')
{ exists } = require('../util')

class ListEntityVM extends Model.build(
  dēfault('take-setting', 5)
  bind('take-actual', from('take-setting').and.subject('length')
    .all.map((setting, length) -> if setting + 1 >= length then length else setting))

  bind('more-count', from.subject('length').and('take-actual')
    .all.map((all, taken) -> max(0, all - taken)))
)

# TODO: it would sure be nice to have janus#138 fixed because it is sad to have
# this not be inline with the rest.
moreButton = template(
  find('.entity-more-count').text(from.vm('more-count'))
  find('.entity-more')
    .classed('has-more', from.vm('more-count').map((x) -> x > 0))
    .on('click', (e, s, { viewModel }) ->
      taken = viewModel.get_('take-setting')
      viewModel.set('take-setting', taken + min(25, taken))
    )
)

ListEntityView = DomView.withOptions({ viewModelClass: ListEntityVM }).build($('
  <span class="janus-inspect-entity janus-inspect-list">
    <span class="entity-title"><span class="entity-type"/></span>
    <span class="entity-content">
      <span class="list-values"></span>
      <button class="entity-more list-more">&hellip;<span class="entity-more-count"/> more</button>
    </span>
  </span>'), template(
  find('.entity-type').text(from('type'))
  find('.list-values').render(from('target').and.vm('take-actual').asVarying()
    .all.map((list, take) -> list.take(take).map(inspect)))

  moreButton
))

module.exports = {
  ListEntityVM, ListEntityView, moreButton,
  registerWith: (library) ->
    library.register(ListInspector, ListEntityView)
}

