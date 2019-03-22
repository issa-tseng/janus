{ DomView, template, find, from } = require('janus')
{ WrappedFunction } = require('./inspector')
{ deindent } = require('../util')
$ = require('janus-dollar')

FunctionPanelView = DomView.build($('
  <div class="janus-inspect-panel janus-inspect-function">
    <div class="panel-title">
      Function
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-content">
      <div class="function-args"/>
      <pre><code class="function-body"/></pre>
    </div>
  </div>'), template(
    find('.function-args')
      .classed('inline', from('arg.pairs').flatMap((as) -> as.length.map((l) -> l < 4)))
      .render(from('arg.pairs').and('arg.given').all.map((as, given) -> as if given))
    find('.function-body').text(from('target').map((f) -> deindent(f.toString())))
))

module.exports = {
  FunctionPanelView,
  registerWith: (library) -> library.register(WrappedFunction, FunctionPanelView, context: 'panel')
}

