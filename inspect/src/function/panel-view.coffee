{ template, find, from } = require('janus')
{ InspectorView } = require('../common/inspector')
{ WrappedFunction } = require('./inspector')
{ deindent, exists } = require('../util')
$ = require('../dollar')

FunctionPanelView = InspectorView.build($('
  <div class="janus-inspect-panel janus-inspect-function highlights">
    <div class="panel-title">
      Function
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-derivation">
      This looks like a <span class="function-known"/>.
    </div>
    <div class="panel-content">
      <div class="function-args"/>
      <pre><code class="function-body"/></pre>
    </div>
  </div>'), template(
    find('.janus-inspect-function').classed('has-known', from('known').map(exists))
    find('.function-known').text(from('known'))
    find('.function-args')
      .classed('inline', from('arg.pairs').flatMap((as) -> as.length.map((l) -> l < 4)))
      .render(from('arg.pairs').and('arg.given').all.map((as, given) -> as if given))
    find('.function-body').text(from('target').map((f) -> deindent(f.toString() ? '(unavailable)')))
))

module.exports = {
  FunctionPanelView,
  registerWith: (library) -> library.register(WrappedFunction, FunctionPanelView, context: 'panel')
}

