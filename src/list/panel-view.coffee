{ DomView, template, find, from, Model } = require('janus')
{ WrappedList } = require('./inspector')
{ KVPair } = require('../common/kv-pair-model')
$ = require('janus-dollar')


ListEntry = DomView.build($('
  <div class="list-entry">
    <button class="list-insert"/>
    <hr/>
    <div class="list-pair"/>
  </div>'), template(
  find('.list-pair').render(from.self((view) -> view.subject))
))


ListPanelView = DomView.build($('
  <div class="janus-inspect-panel janus-inspect-list">
    <div class="panel-title">
      List
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-content">
      <div class="list-list"/>
      <button class="list-insert list-insert-last"/>
    </div>
  </div>'), template(
  find('.janus-inspect-list')
    .classed('derived', from('derived'))
    .classed('read-only', from.app().map((app) -> !(app.popValuator?)))
  find('.list-list')
    .render(from('list').map((target) -> target.enumerate().map((key) -> new KVPair({ target, key }))))
      .options({ renderItem: (r) -> r.context('list-entry') })

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

