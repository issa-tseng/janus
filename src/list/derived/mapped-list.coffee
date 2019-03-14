{ DomView, template, find, from } = require('janus')
$ = require('janus-dollar')
{ KVPair } = require('../../common/kv-pair-model')
{ inspect } = require('../../inspect')
{ WrappedFunction } = require('../../function/inspector')

MappedListEntry = DomView.build($('
  <div class="list-entry list-mapped">
    <span class="list-index"/>
    <span class="list-value value-source"/>
    <span class="list-mapping"/>
    <span class="list-value value-target"/>
  </div>'), template(
  find('.list-index').text(from('key'))

  find('.value-source').render(from('target').and('key')
    .all.flatMap((list, key) -> list.parent.get(key).map(inspect)))
  find('.value-target').render(from('target').and('key')
    .all.flatMap((list, key) -> list.get(key).map(inspect)))

  find('.list-mapping').on('mouseenter', (event, pair, view) ->
    return unless view.options.app.flyout?
    mapped = pair.get_('target')
    arg = mapped.parent.get_(pair.get_('key'))
    wf = new WrappedFunction(mapped.mapper, [ arg ])
    view.options.app.flyout($(event.target), wf, 'panel')
  )
))

module.exports = {
  MappedListEntry
  registerWith: (library) -> library.register(KVPair, MappedListEntry, { context: 'list-entry', subtype: 'mapped' })
}

