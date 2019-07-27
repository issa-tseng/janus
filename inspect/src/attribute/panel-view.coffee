{ template, find, from } = require('janus')
{ InspectorView } = require('../common/inspector')
$ = require('../dollar')
{ AttributeInspector } = require('./inspector')
{ inspect } = require('../inspect')

yn = (bool) -> if bool is true then 'yes' else 'no'

AttributePanelView = InspectorView.build($('
  <div class="janus-inspect-panel janus-inspect-attribute highlights">
    <div class="panel-title">
      <span class="attribute-type"/>
      <button class="janus-inspect-pin" title="Pin"/>
    </div>
    <div class="panel-derivation">
      Attached to "<span class="attribute-key"/>"
      of <span class="attribute-parent"/>
    </div>
    <div class="panel-content">
      <dl>
        <dt>Key</dt><dd class="attribute-key"/>
        <dt>Value</dt><dd class="attribute-value"/>
        <dt>Writes default</dt><dd class="attribute-writes-default"/>
        <dt>Transient</dt><dd class="attribute-transient"/>
      </dl>
      <dl class="attribute-enum">
        <dt>Nullable</dt><dd class="attribute-enum-nullable"/>
        <dt>Enum values</dt><dd class="attribute-enum-values"/>
      </dl>
      <div class="attribute-pairs"/>
    </div>
  </div>'), template(
    find('.janus-inspect-attribute').classGroup('type-', from('type'))

    find('.attribute-type').text(from('type'))
    find('.attribute-key').text(from('key'))
    find('.attribute-parent').render(from('parent').map(inspect))
    find('.attribute-value').render(from('value').map(inspect))
    find('.attribute-writes-initial').text(from('target').map((t) -> yn(t.writeInitial)))
    find('.attribute-transient').text(from('target').map((t) -> yn(t.transient)))
    find('.attribute-pairs')
      .classed('has-pairs', from('pairs').flatMap((p) -> p.nonEmpty()))
      .render(from('pairs'))

    find('.attribute-enum-nullable').text(from('target').map((t) -> yn(t.nullable)))
    find('.attribute-enum-values').render(from('enum-values').map(inspect))
))

module.exports = {
  AttributePanelView,
  registerWith: (library) -> library.register(AttributeInspector, AttributePanelView, context: 'panel')
}

