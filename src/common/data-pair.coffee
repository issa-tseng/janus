# maybe not what you were looking for. just some utilities common across all data
# pairs. there actually isn't a data pair root abstraction (a lesson learned the
# hard way), there is only a convention on "target"/"key" data and html classnames.

# type is just used to name the target in the valuator.
valuate = (type, pair, view) ->
  target = pair.get_('target')
  key = pair.get_('key')

  old = target.get_(key)
  values = [{ name: type, value: target }, { name: 'old', value: old }]
  options = { title: 'Edit Value', values, initial: old }
  view.options.app.valuator(view.artifact(), options, target.set(key))
    .destroyWith(view)
  return

module.exports = { valuate }

