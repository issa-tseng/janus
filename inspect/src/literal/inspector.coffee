{ floor } = Math
{ List, initial, Model, bind, from } = require('janus')
{ DateTime } = require('luxon')
{ isPrimitive, isArray } = require('janus').util

TruncatingLiteral = Model.build(
  # expects string: String

  # skipping use of BooleanAttribute for now to keep the html classes consistent.
  # eventually the stdlib button renderer should take custom classes.
  initial('truncate', true)

  bind('more_count', from('string').map((str) ->
    more = str.length - 300
    if more >= 1000000
      "#{floor(more / 100000) / 10}M"
    else if more > 1000
      "#{floor(more / 100) / 10}K"
    else
      more
  ))
)

inspectLiteral = (x) ->
  if isPrimitive(x)
    string = JSON.stringify(x)
    # we use 350 here but 300 in the actual truncation so we don't do silly things
    # like truncate only by one char.
    if string.length > 350 then new TruncatingLiteral({ string })
    else string
  else if !x?
    'Ø'
  else
    x

class ArrayInspector extends Model
  isInspector: true
  update: -> this.set('length', this.get_('target').length)
  @inspect: (target) -> new ArrayInspector({ target, length: target.length })

class DateInspector extends Model
  isInspector: true
  @inspect: (date) -> new DateInspector({ target: DateTime.fromJSDate(date) })

module.exports = {
  TruncatingLiteral, ArrayInspector, DateInspector,
  registerWith: (library) ->
    library.register(type, inspectLiteral) for type in [ String, Number, Boolean, null ]
    library.register(Array, ArrayInspector.inspect)
    library.register(Date, DateInspector.inspect)
    return
}

