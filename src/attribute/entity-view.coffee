{ DomView, template, find, from } = require('janus')
$ = require('janus-dollar')
{ AttributeInspector } = require('./inspector')
{ inspect } = require('../inspect')

AttributeEntityView = DomView.build($('
  <span class="janus-inspect-entity janus-inspect-attribute">
    <span class="entity-title"/>
    <span class="entity-content">
      "<span class="attribute-key"/>"
      of <span class="attribute-parent"/>
    </span>
  </span>'), template(
    find('.entity-title').text(from('type'))

    find('.attribute-parent').render(from('parent').map(inspect))
    find('.attribute-key').text(from('key'))
))

module.exports = {
  AttributeEntityView,
  registerWith: (library) -> library.register(AttributeInspector, AttributeEntityView)
}

