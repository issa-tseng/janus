{ DomView, template, find, from, Model, bind, attribute } = require('janus')
{ WrappedList } = require('./inspector')
{ KVPair } = require('../common/kv-pair-model')
$ = require('janus-dollar')
{ min, max } = Math


ListEntry = DomView.build($('
  <div class="list-entry">
    <button class="list-insert" title="Insert Item"/>
    <hr/>
    <div class="list-pair"/>
  </div>'), template(
  find('.list-pair').render(from.self((view) -> view.subject))
))

# TODO: a LOT of overlap with ListEntityVM
class ListPanelVM extends Model.build(
  bind('list', from('subject').get('list'))
  bind('length', from('list').flatMap((l) -> l.length))
  attribute('take', class extends attribute.Number
    default: ->
      if this.model.get_('subject').get_('list').length_ is 11 then 11
      else 10
  )
  bind('tail', from('length').and('take').all.map((l, t) -> max(0, l - t)))
)

ListPanelView = DomView.withOptions({ viewModelClass: ListPanelVM }).build($('
  <div class="janus-inspect-panel janus-inspect-list">
    <div class="panel-title">
      List
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-content">
      <div class="list-list"/>
      <button class="list-more">&hellip; <span class="list-more-count"/> more</button>
      <div class="list-last-item"/>
      <button class="list-insert list-insert-last"/>
    </div>
  </div>'), template(
  find('.janus-inspect-list')
    .classed('derived', from('subject').get('derived'))
    .classed('read-only', from.app().map((app) -> !(app.popValuator?)))

  find('.list-list')
    .render(from('list').and.self().all.map((target, view) ->
      target.enumerate()
        .map((key) -> new KVPair({ target, key }))
        .take(view.subject.get('take'))))
      .options({ renderItem: (r) -> r.context('list-entry') })

  find('.list-more-count').text(from('tail'))
  find('.list-more')
    .classed('has-more', from('tail').map((t) -> t > 0))
    .on('click', (e, subject) ->
      taken = subject.get_('take')
      naive = taken + min(100, taken)
      target = # it's always dumb when a button takes up space and says "show me 1 more!"
        if naive is subject.get_('length') - 1 then naive + 1
        else naive
      subject.set('take', target)
    )

  find('.list-last-item').render(from('list').and('length')
    .all.map((target, length) -> new KVPair({ target, key: length - 1 })))

  find('.janus-inspect-list').on('click', '.list-insert', (event, subject, view) ->
    event.stopPropagation() # don't pop multiple up the stack
    target = $(event.target)
    return if target.hasClass('valuating')
    # TODO: don't put strings here:
    valuator = view.options.app.popValuator('Insert List Item', (result) ->
      idx =
        if target.hasClass('list-insert-last') then undefined
        else target.closest('li').prevAll().length
      subject.get_('list').add(result, idx)
    )

    # TODO: less than elegant. i don't like direct stateful mutation.
    target.addClass('valuating')
    valuator.on('destroying', -> target.removeClass('valuating'))
  )
))


module.exports = {
  ListEntry, ListPanelView
  registerWith: (library) ->
    library.register(KVPair, ListEntry, context: 'list-entry')
    library.register(WrappedList, ListPanelView, context: 'panel')
}

