{ template, find, from } = require('janus')
{ InspectorView } = require('../common/inspector')
$ = require('janus-dollar')
{ DataPair, WrappedModel } = require('./inspector')


ModelPanelView = InspectorView.build($('
  <div class="janus-inspect-panel janus-inspect-model highlights">
    <div class="panel-title">
      <span class="model-type"/><span class="model-subtype"/>
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-content"/>
  </div>'), template(
    find('.model-type').text(from('type'))
    find('.model-subtype').text(from('subtype'))
    find('.panel-content').render(from('target')
      .map((target) -> target.enumerate().map((key) -> new DataPair({ target, key }))))
))


module.exports = {
  ModelPanelView
  registerWith: (library) ->
    library.register(WrappedModel, ModelPanelView, context: 'panel')
}

