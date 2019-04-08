{ DomView } = require('janus')

class InspectorView extends DomView
  highlight: -> this.subject.get_('target')

module.exports = { InspectorView }

