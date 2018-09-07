{ min, max } = Math
{ DomView, template, find, from, Model, attribute, bind, dēfault } = require('janus')
$ = require('janus-dollar')
{ inspect } = require('../inspect')
{ WrappedList } = require('./inspector')
{ exists } = require('../util')

ListEntityVM = Model.build(
  bind('list', from('subject').watch('list'))
  dēfault('take', 5)
  bind('more_count', from('subject').watch('length').and('take')
    .all.map((all, taken) -> max(0, all - taken)))
)

ListEntityView = DomView.withOptions({ viewModelClass: ListEntityVM }).build($('
  <div class="janus-inspect-entity janus-inspect-list">
    <span class="entity-title">List<span class="entity-subtitle"/></span>
    <span class="entity-content">
      <span class="list-values"></span>
      <button class="list-more">&hellip;<span class="list-more-count"/> more</button>
    </span>
  </div>'), template(

  find('.entity-subtitle')
    .classed('has-subtitle', from('subject').watch('subtype').map(exists))
    .text(from('subject').watch('subtype'))

  find('.list-values').render(from('list').and('take').asVarying()
    .all.map((list, take) -> list.take(take).map(inspect)))

  find('.list-more-count')
    .classed('has-more', from('more_count').map((x) -> x > 0))
    .text(from('more_count'))

  find('.list-more').on('click', (_, subject) ->
    taken = subject.get('take')
    subject.set('take', taken + min(25, taken))
  )
))

module.exports = {
  ListEntityView,
  registerWith: (library) ->
    library.register(WrappedList, ListEntityView)
}

