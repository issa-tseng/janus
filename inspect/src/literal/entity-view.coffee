{ DomView, template, find, from, initial, List, bind, Trait } = require('janus')
{ InspectorView } = require('../common/inspector')
{ ListEntityVM, moreButton } = require('../list/entity-view')
{ TruncatingLiteral, DateInspector, ArrayInspector } = require('./inspector')
$ = require('janus-dollar')
{ inspect } = require('../inspect')

################################################################################
# STRING LITERAL

TruncatingLiteralView = DomView.build($('
  <span class="janus-inspect-entity janus-literal">
    <span class="literal-content"/>
    <button class="entity-more">&hellip;<span class="entity-more-count"/> more</button>
  </span>'), template(

  find('.literal-content').text(from('string').and('truncate')
    .all.map((str, truncate) -> if truncate then str.slice(0, 300) else str))

  find('.entity-more-count').text(from('more_count'))

  find('.entity-more')
    .classed('has-more', from('truncate'))
    .on('click', (_, subject) -> subject.set('truncate', false))
))

################################################################################
# DATE/TIME LITERAL

DateTimeLiteralView = DomView.build($('
  <span class="janus-inspect-entity janus-inspect-date no-panel">
    <span class="entity-title">Date</span>
    <span class="entity-content">
      <span class="date-date"/>T<span class="date-time"/><span class="date-tz"/>
    </span>
  </span>'), template(
  find('.date-date').text(from('target').map((date) -> date.toISODate()))
  find('.date-time').text(from('target').map((date) -> date.toFormat('HH:mm:ss.SSS')))
  find('.date-tz').text(from('target').map((date) -> date.toFormat('ZZ')))
))

################################################################################
# ARRAY LITERAL

ListForArray = Trait(
  initial('list-bump', 0)
  bind('list', from.subject('target').and('list-bump').all.map((a) -> new List(a)))
)
class ArrayEntityVM extends ListEntityVM.build(ListForArray)
  update: ->
    this.set('list-bump', this.get_('list-bump') + 1)
    this.get_('subject').update()
    return

# we use list classes here because we do want pretty much all of its styles.
ArrayEntityView = InspectorView.withOptions({ viewModelClass: ArrayEntityVM }).build($('
  <span class="janus-inspect-entity janus-inspect-list highlights">
    <span class="entity-title">Array</span>
    <span class="entity-content">
      <span class="list-values"></span>
      <button class="entity-more list-more">&hellip;<span class="entity-more-count"/> more</button>
      <button class="array-update"/>
    </span>
  </span>'), template(
  find('.list-values').render(from.vm('list').and.vm('take-actual').asVarying()
    .all.map((list, take) -> list.take(take).map(inspect)))

  moreButton
  find('.array-update').on('click', (e, s, { viewModel }) -> viewModel.update())
))

module.exports = {
  TruncatingLiteral,
  DateTimeLiteralView,
  ListForArray, ArrayEntityVM, ArrayEntityView,
  registerWith: (library) ->
    library.register(TruncatingLiteral, TruncatingLiteralView)
    library.register(DateInspector, DateTimeLiteralView)
    library.register(ArrayInspector, ArrayEntityView)
}

