{ template, find, from } = require('janus')
{ InspectorView } = require('../common/inspector')
{ SetInspector } = require('./inspector')
{ ListEntityVM, ListEntityView } = require('../list/entity-view')
{ inspect } = require('../inspect')

SetEntityView = InspectorView.build(ListEntityVM, $('
  <span class="janus-inspect-entity janus-inspect-list highlights">
    <span class="entity-title">Set</span>
    <span class="entity-content">
      <span class="list-values"></span>
      <button class="entity-more list-more">&hellip;<span class="entity-more-count"/> more</button>
    </span>
  </span>'), template(
  find('.list-values').render(from('target').and.vm('take-actual').asVarying()
    .all.map((set, take) -> set._list.take(take).map(inspect))),
  ListEntityView.template.moreButton
))

module.exports = {
  registerWith: (library) -> library.register(SetInspector, SetEntityView)
}

