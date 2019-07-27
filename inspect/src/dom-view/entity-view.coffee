{ template, find, from } = require('janus')
{ InspectorView } = require('../common/inspector')
$ = require('../dollar')
{ DomViewInspector } = require('./inspector')
{ pluralize } = require('../util')


DomViewEntityView = InspectorView.build($('
  <span class="janus-inspect-entity janus-inspect-domview highlights">
    <span class="entity-title">DomView<span class="domview-subtype"/></span>
    <span class="entity-content">
      <span class="domview-mutation-count"/>
      <span class="domview-mutation-label"/>
    </span>
  </span>'), template(

  find('.domview-subtype').text(from('subtype'))
  find('.domview-mutation-count').text(from('mutations').flatMap((ms) -> ms.length))
  find('.domview-mutation-label').text(from('mutations').flatMap((ms) ->
    ms.length.map(pluralize('binding', 'bindings'))))
))

module.exports = {
  DomViewEntityView,
  registerWith: (library) -> library.register(DomViewInspector, DomViewEntityView)
}

