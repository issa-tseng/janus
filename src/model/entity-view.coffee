{ template, find, from } = require('janus')
{ InspectorView } = require('../common/inspector')
$ = require('janus-dollar')
{ WrappedModel } = require('./inspector')
{ pluralize } = require('../util')


ModelEntityView = InspectorView.build($('
  <span class="janus-inspect-entity janus-inspect-model highlights">
    <span class="entity-title"><span class="model-type"/><span class="model-subtype"/></span>
    <span class="entity-content">
      <span class="model-identifier"></span>
      <span class="model-pairs">(<span class="model-count"/> <span class="model-count-label"/>)</span>
    </span>
  </span>'), template(

  find('.model-type').text(from('type'))
  find('.model-subtype').text(from('subtype'))

  find('.model-identifier').text(from('identifier'))

  find('.model-count').text(from('target').flatMap((t) -> t.length))
  find('.model-count-label').text(from('target').flatMap((t) -> t.length)
    .map(pluralize('pair', 'pairs')))
))

module.exports = {
  ModelEntityView,
  registerWith: (library) -> library.register(WrappedModel, ModelEntityView)
}

