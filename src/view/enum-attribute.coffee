{ Varying, DomView, from, template, find, Base, List } = require('janus')
{ Enum } = require('janus').attribute
{ isArray, isPrimitive, uniqueId } = require('janus').util
{ stringifier, asList } = require('../util/util')

$ = require('janus-dollar')

class EnumAttributeEditView extends DomView
  dom: -> $('<select/>')

  _initialize: ->
    # only do this once for perf.
    this._stringifier = stringifier(this)

  # if we have the necessary mapping, locate the correct value and apply if found.
  _updateVal: (select) ->
    return unless this._textBindings?
    selected = this.subject.getValue()
    for binding in this._textBindings.list when binding.item is selected
      select.val(binding.optionId)
      return
    return

  _optionsList: ->
    Varying.of(this.subject.values()).map((values) =>
      list = asList(values)
      if this.subject.nullable is true
        new List([ null ]).concat(list)
      else
        list
    )

  _render: ->
    select = this.dom()

    # map our values onto options.
    this._optionsList().react((list) =>
      # we have a new list; anything we'd previously had is completely invalid.
      this._removeAll(select)

      # now that we have a definitive list, map items to options.
      this._textBindings = bindings = list.map((item) => this._generateTextBinding(item))
      this._hookBindings(select, bindings)

      # add all elements as the map will have already resolved by now so
      # we don't get add events for the initial set.
      this._add(select, binding.dom, idx) for binding, idx in bindings.list
    )

    select # return artifact.

  # TODO: long and repetitive with the above. but also not.
  _attach: (select) ->
    initial = true
    this._optionsList().react((list) =>
      this._removeAll(select) unless initial is true

      options = select.children().get()

      this._textBindings = bindings = list.map((item) =>
        if initial is true
          rawOption = options.shift()
          option = $(rawOption)
          textBinding = this._stringifier.flatMap((f) -> f(item)).react(false, (text) -> option.text(text))
          textBinding.item = item
          textBinding.optionId = rawOption.value
          textBinding.dom = option
          textBinding
        else
          this._generateTextBinding(item)
      )
      this._hookBindings(select, bindings)
    )
    initial = false
    return

  _generateTextBinding: (item) ->
    option = $('<option/>')

    # use our standard stringifier to convert items to text; remember the binding.
    textBinding = this._stringifier.flatMap((f) -> f(item)).react((text) -> option.text(text))

    # generate and save a unique id, along with relevant state data.
    id = this._generateId(item)
    option.attr('value', id)
    textBinding.item = item
    textBinding.optionId = id
    textBinding.dom = option
    textBinding # as with ListView, return the binding.

  _hookBindings: (select, bindings) ->
    # listen to additions/removals, and modify the dom appropriately.
    this.listenTo(bindings, 'added', (binding, idx) => this._add(select, binding.dom, idx))
    this.listenTo(bindings, 'removed', (binding) =>
      binding.dom.remove()
      binding.stop()
    )
    return

  # try to use the dry value if possible, otherwise come up with a viable
  # unique primitive id. preëmptive toString will save time retrieving from
  # dom.
  _generateId: (value) ->
    if !value?
      toString.call(value)
    else if isPrimitive(value)
      value.toString()
    else
      uniqueId().toString()

  _removeAll: (select) ->
    # clean up the bindings in the binding list, then the binding list itself.
    if this._textBindings?
      binding.stop() for _, binding of this._textBindings.list
      this.unlistenTo(this._textBindings)
      this._textBindings.destroy()

    # and empty out all the options.
    select.empty()
    return

  _add: (dom, option, idx) ->
    children = dom.children()
    if idx is 0
      dom.prepend(option)
    else if idx is children.length
      dom.append(option)
    else
      children.eq(idx).before(option)

    this._updateVal(dom)
    return

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
      selectedId = selectedOption.attr('value')
      for binding in this._textBindings.list when binding.optionId is selectedId
        subject.setValue(binding.item)
        return
      return
    select.on('change input', update)
    update()
    return

module.exports = { EnumAttributeEditView, registerWith: (library) -> library.register(Enum, EnumAttributeEditView, context: 'edit') }

