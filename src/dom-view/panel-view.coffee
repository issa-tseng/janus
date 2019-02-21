{ DomView, template, find, from } = require('janus')
$ = require('janus-dollar')
{ Mutation, DomViewInspector } = require('./inspector')
{ inspect } = require('../inspect')
{ exists } = require('../util')


MutationView = DomView.build($('
  <div class="mutation">
    <div class="mutation-selector"/>
    <div class="mutation-binding"/>
    <span class="mutation-type">
      <span class="mutation-operation"/><span class="mutation-param"/>
    </span>
  </div>'), template(

  find('.mutation-selector').text(from('selector'))
  find('.mutation-operation').text(from('operation'))
  find('.mutation-param')
    .text(from('param'))
    .classed('has-param', from('param').map(exists))
  find('.mutation-binding').render(from('binding').map(inspect))
))

DomViewPanelView = DomView.build($('
  <div class="janus-inspect-panel janus-inspect-domview">
    <div class="panel-title">
      DomView<span class="domview-subtype"/>
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-content">
      <div class="domview-mutations"/>
    </div>
  </div>'), template(

  find('.domview-subtype').text(from('subtype'))
  find('.domview-mutations').render(from('mutations'))
))

module.exports = {
  MutationView
  DomViewPanelView
  registerWith: (library) ->
    library.register(Mutation, MutationView)
    library.register(DomViewInspector, DomViewPanelView, context: 'panel')
}

