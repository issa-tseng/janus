{ DomView, template, find, from } = require('janus')
$ = require('janus-dollar')
{ WrappedModel } = require('./inspector')


ModelPanelView = DomView.build($('
  <div class="janus-inspect-panel janus-inspect-model">
    <div class="panel-title">
      <span class="model-type"/><span class="model-subtype"/>
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-content"/>
  </div>'), template(
    find('.model-type').text(from('type'))
    find('.model-subtype').text(from('subtype'))
    find('.panel-content').render(from('pairs'))
))


module.exports = {
  ModelPanelView
  registerWith: (library) ->
    library.register(WrappedModel, ModelPanelView, context: 'panel')
}

