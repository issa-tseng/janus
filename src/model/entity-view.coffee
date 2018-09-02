{ DomView, template, find, from } = require('janus')
$ = require('janus-dollar')
{ WrappedModel } = require('./inspector')


ModelEntityVM = Model.build(
  bind('model', from('subject').watch('model'))

  attribute('expand.shown', attribute.Boolean)
  bind('expand.object', from('subject').and('expand.shown')
    .all.map((subject, show) -> subject if show))
)

ModelEntityView = DomView.withOptions({ viewModelClass: ModelEntityVM }).build($('
  <div class="janus-inspect-entity janus-inspect-model">
    <span class="entity-title"><span class="model-type"/><span class="model-subtype"/></span>
    <span class="entity-content">
      <span class="model-identifier"></span>
      <span class="model-pairs">(<span class="model-count"/> pairs)</span>
    </span>
  </div>'), template(

  find('.model-type').text(from('subject').watch('type'))
  find('.model-subtype').text(from('subject').watch('subtype'))

  find('.model-identifier').text(from('subject').watch('identifier'))
  find('.model-count').text(from('model').flatMap((model) -> model.watchLength()))
))

module.exports = {
  ModelEntityView,
  registerWith: (library) -> library.register(WrappedModel, ModelEntityView)
}

