{ Library } = require('janus')

# get inspectors and create inspect().
inspectorLibrary = new Library()
require('./model/inspector').registerWith(inspectorLibrary)
require('./varying/inspector').registerWith(inspectorLibrary)
require('./literal/inspector').registerWith(inspectorLibrary)
inspect = (x) -> inspectorLibrary.get(x)?(x) ? x

module.exports = { inspect }

