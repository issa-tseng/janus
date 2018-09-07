{ DomView, template, find, from } = require('janus')
$ = require('janus-dollar')
{ WrappedModel } = require('./inspector')
{ pluralize } = require('../util')


ModelEntityView = DomView.build($('
  <div class="janus-inspect-entity janus-inspect-model">
    <span class="entity-title"><span class="model-type"/><span class="model-subtype"/></span>
    <span class="entity-content">
      <span class="model-identifier"></span>
      <span class="model-pairs">(<span class="model-count"/> <span class="model-count-label"/>)</span>
    </span>
  </div>'), template(

  find('.model-type').text(from('type'))
  find('.model-subtype').text(from('subtype'))

  find('.model-identifier').text(from('identifier'))

  find('.model-count').text(from('model').flatMap((m) -> m.watchLength()))
  find('.model-count-label').text(from('model').flatMap((m) -> m.watchLength())
    .map(pluralize('pair', 'pairs')))
))

module.exports = {
  ModelEntityView,
  registerWith: (library) -> library.register(WrappedModel, ModelEntityView)
}

