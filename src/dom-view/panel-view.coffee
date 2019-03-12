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

  find('.mutation-selector')
    .text(from('selector'))
    .classed('repeated', from('repeated-selector'))
  find('.mutation-operation').text(from('operation'))
  find('.mutation-param')
    .text(from('param'))
    .classed('has-param', from('param').map(exists))
  find('.mutation-binding').render(from('binding').map(inspect))
))

class DomViewPanelView extends DomView.build($('
    <div class="janus-inspect-panel janus-inspect-domview">
      <div class="panel-title">
        DomView<span class="domview-subtype"/>
        <button class="janus-inspect-pin" title="Pin"/>
      </div>
      <div class="panel-content">
        <div class="domview-mutations"/>
        <div class="domview-display">
          <span class="domview-display-label">View Preview</span>
        </div>
      </div>
    </div>'), template(

    find('.domview-subtype').text(from('subtype'))
    find('.domview-mutations').render(from('mutations'))
  ))

  _render: ->
    artifact = super()
    domview = this.subject.get_('domview')
    target = domview.artifact()
    if (target.closest('html').length is 0) or (target.parent().hasClass('domview-display') and (target.closest('.flyout').length isnt 0))
      artifact.find('.domview-display').prepend(target)
      domview.wireEvents()
    artifact

module.exports = {
  MutationView
  DomViewPanelView
  registerWith: (library) ->
    library.register(Mutation, MutationView)
    library.register(DomViewInspector, DomViewPanelView, context: 'panel')
}

