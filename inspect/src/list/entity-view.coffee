{ min, max } = Math
{ template, find, from, Model, attribute, bind, initial } = require('janus')
{ InspectorView } = require('../common/inspector')
$ = require('../dollar')
{ inspect } = require('../inspect')
{ ListInspector } = require('./inspector')
{ exists } = require('../util')

class ListEntityVM extends Model.build(
  initial('take-setting', 5)
  bind('take-actual', from('take-setting').and.subject('length')
    .all.map((setting, length) -> if setting + 1 >= length then length else setting))

  bind('more-count', from.subject('length').and('take-actual')
    .all.map((all, taken) -> max(0, all - taken)))
)

ListEntityView = InspectorView.build(ListEntityVM, $('
  <span class="janus-inspect-entity janus-inspect-list highlights">
    <span class="entity-title"><span class="entity-type"/></span>
    <span class="entity-content">
      <span class="list-values"></span>
      <button class="entity-more list-more">&hellip;<span class="entity-more-count"/> more</button>
    </span>
  </span>'), template(
  find('.entity-type').text(from('type'))
  find('.list-values').render(from('target').and.vm('take-actual').asVarying()
    .all.map((list, take) -> list.take(take).map(inspect)))

  template(
    'moreButton'
    find('.entity-more-count').text(from.vm('more-count'))
    find('.entity-more')
      .classed('has-more', from.vm('more-count').map((x) -> x > 0))
      .on('click', (e, s, { viewModel }) ->
        taken = viewModel.get_('take-setting')
        viewModel.set('take-setting', taken + min(25, taken))
      )
  )
))

module.exports = {
  ListEntityVM, ListEntityView,
  registerWith: (library) ->
    library.register(ListInspector, ListEntityView)
}

