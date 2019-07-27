
dollar = (x) -> dollar.$(x)
dollar.set = ($) -> this.$ ?= $
module.exports = dollar

