{ Varying, DomView, from, template, find, Base, List } = require('janus')
{ Enum } = require('janus').attribute
{ isArray, isPrimitive, uniqueId } = require('janus').util
{ stringifier, asList } = require('../util/util')

$ = require('../util/dollar')

class EnumAttributeEditView extends DomView
  dom: -> $('<select/>')

  # if we have the necessary mapping, locate the correct value and apply if found.
  _updateVal: (select) ->
    return unless this._valueMap?
    (id = _id; break) for _id, value of this._valueMap when value is this.subject.getValue()
    select.val(id) if id? # TODO: this may not work with zepto/cheerio.

  _render: ->
    select = this.dom()

    # because we don't necessarily have a safe reference to put down as each
    # option's value, we'll just generate ints and same a mapping here.
    # TODO: someday if we drop IE/Node 0.10 we could use WeakMap?
    this._valueMap = {}
    this._textBindingsMap = {}

    # map our values onto options.
    Varying.of(this.subject.values()).map(asList).react((list) =>
      # we have a new list; anything we'd previously had is completely invalid.
      this._removeAll(select)

      # add a null entry at the top if relevant.
      if this.subject.nullable is true
        list = new List([ null ]).concat(list)

      # now that we have a definitive list, map items to options.
      this._options = options = list.map((item) =>
        option = $('<option/>')

        # use our standard stringifier to convert items to text; remember the binding.
        textBinding = stringifier(this).flatMap((f) -> f(item)).react((text) -> option.text(text))

        # generate and save a unique id, along with relevant state data.
        id = this._generateId(item)
        option.attr('value', id)
        this._valueMap[id] = item
        this._textBindingsMap[id] = textBinding

        option # return the dom node.
      )

      # listen to additions/removals, and modify the dom appropriately.
      this.listenTo(options, 'added', (option, idx) => this._add(select, option, idx))
      this.listenTo(options, 'removed', (option) => this._remove(option))

      # add all elements as the map will have already resolved by now so
      # we don't get add events for the initial set.
      this._add(select, option, idx) for option, idx in options.list
    )

    select # return artifact.

  # try to use the dry value if possible, otherwise come up with a viable
  # unique primitive id. preëmptive toString will save time retrieving from
  # dom.
  _generateId: (value) ->
    if !value?
      toString.call(value)
    else if isPrimitive(value)
      value.toString()
    else if value._id?
      value._id.toString()
    else
      uniqueId().toString()

  _removeAll: (select) ->
    # first, invalidate all references and stop old reactions so we don't
    # leak resources.
    binding.stop() for _, binding of this._textBindingsMap if this._textBindingsMap?
    this._textBindingsMap = {}
    this._valueMap = {}

    # absolve ourselves of the previous options mapped list.
    if this._options?
      this.unlistenTo(this._options)
      this._options.destroy()

    # then empty out all the options.
    select.empty()

  _add: (dom, option, idx) ->
    children = dom.children()
    if idx is 0
      dom.prepend(option)
    else if idx is children.length
      dom.append(option)
    else
      children.eq(idx).before(option)

    this._updateVal(dom)

  _remove: (option) ->
    id = option.attr('value')

    this._textBindingsMap[id].stop()
    delete this._textBindingsMap[id]
    delete this._valueMap[id]

    option.remove()

  _wireEvents: ->
    select = this.artifact()
    subject = this.subject

    # bind from model.
    subject.watchValue().react(=> this._updateVal(select))

    # bind to model. do so once immediately so that if the select is non-nullable
    # then the entry the user sees is what is saved.
    update = =>
      selectedOption = select.children(':selected')
      selectedOption = select.children(':first') if selectedOption.length is 0
      subject.setValue(this._valueMap[selectedOption.val()])
    select.on('change input', update)
    update()

module.exports = { EnumAttributeEditView, registerWith: (library) -> library.register(Enum, EnumAttributeEditView, context: 'edit') }

