{ Case } = require('janus')

reference = Case.build('org.janusjs.inspect.reference',
  'get', 'parent',
  'attr', 'attrModel', 'attrValue', 'attrEnumValues',
  'viewSubject', 'viewVm', 'mutator',
  'varyingValue', 'varyingInner', 'varyingApplicant'
)

module.exports = { reference }

