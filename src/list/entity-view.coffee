{ min, max } = Math
{ DomView, template, find, from, Model, attribute, bind, dēfault } = require('janus')
$ = require('janus-dollar')
{ inspect } = require('../inspect')
{ WrappedList } = require('./inspector')
{ exists } = require('../util')

class ListEntityVM extends Model.build(
    bind('list', from('subject').get('list'))
    dēfault('take', 5)
    bind('more_count', from('subject').get('length').and('take')
      .all.map((all, taken) -> max(0, all - taken)))
  )

  _initialize: ->
    this.set('take', 6) if this.get_('subject').get_('list').length_ is 6

ListEntityView = DomView.withOptions({ viewModelClass: ListEntityVM }).build($('
  <div class="janus-inspect-entity janus-inspect-list">
    <span class="entity-title"><span class="entity-type"/><span class="entity-subtitle"/></span>
    <span class="entity-content">
      <span class="list-values"></span>
      <button class="entity-more list-more">&hellip;<span class="entity-more-count"/> more</button>
    </span>
  </div>'), template(

  find('.entity-type').text(from('subject').get('type'))

  find('.entity-subtitle')
    .classed('has-subtitle', from('subject').get('subtype').map(exists))
    .text(from('subject').get('subtype'))

  find('.list-values').render(from('list').and('take').asVarying()
    .all.map((list, take) -> list.take(take).map(inspect)))

  find('.entity-more-count')
    .text(from('more_count'))

  find('.entity-more')
    .classed('has-more', from('more_count').map((x) -> x > 0))
    .on('click', (_, subject) ->
      taken = subject.get_('take')
      subject.set('take', taken + min(25, taken))
    )
))

module.exports = {
  ListEntityView,
  registerWith: (library) ->
    library.register(WrappedList, ListEntityView)
}

