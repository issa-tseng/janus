{ Map } = require('janus')

# because edit-valuation (ad-hoc editing an existing data value) is:
# 1 repeated across eg list/map/model, and varying entity/panel, and
# 2 sometimes cascading (eg editing a varying that's actually a representation of
#   a data structure data pair),
# we just provide one central spot to call into here. we export all these methods
# for testing (eventually) but the proper entrypoint is valuate()/tryValuate().
#
# not all valuator invocation is here, though! eg list and model new-value are
# elsewhere as they specify new values.


_pair = (pair, view) ->
  target = pair.get_('target')
  return false if target.isDerivedList is true or target.isDerivedMap is true

  key = pair.get_('key')
  old = target.get_(key)

  type = # type gives the title and the name given to the existing structure ref.
    if target.isList is true then 'List'
    else if target.isModel is true then 'Model'
    else if target.isMap is true then 'Map'
    else 'Data'

  values = [{ name: type.toLowerCase(), value: target }, { name: 'old', value: old }]
  values.splice(1, 0, { name: 'key', value: key }) if target.isMap is true
  options = { title: "Edit #{type} Value", values, initial: old }
  view.options.app.valuator(view.artifact(), options, target.set(key))
    .destroyWith(view)
  return true


_varying = (inspector, view) ->
  varying = inspector.varying
  old = varying.get()
  values = [{ name: 'varying', value: varying }, { name: 'old', value: old }]
  options = { title: 'Set Varying Value', values, initial: old }
  view.options.app.valuator(view.artifact(), options, (v) -> varying.set(v))
    .destroyWith(view)
  return true


# x might be a list or map/model keypair (in which case it should have "target"
# and "key" data values), or else a varying that might target a keypair.
#
# returns true or false depending on whether it successfully starts the valuation
# process, so feedback/event handling can be done if relevant.
valuate = (x, view) ->
  if x.isWrappedVarying is true
    return false if x.get_('derived') is true # bail if flattened/mapped.

    # figure out the derivation of the varying. if it's a primitive varying that isn't
    # directly representative of some data structure value just process and bail.
    derivation = x.get_('derivation')
    return _varying(x, view) unless derivation?

    # otherwise we can get our structure and proceed as if that's our edit target.
    x = new Map({ target: x.varying.__owner, key: derivation.get_('arg') })

  # if we have arrived here we have some kind of datapair structure in x.
  return _pair(x, view)


# this event handling pattern is so common we may as well just centralize it here.
tryValuate = (event, subject, view) -> event.preventDefault() if valuate(subject, view)


module.exports = { valuate, tryValuate, _pair, _varying }

