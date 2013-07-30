util = require('../../util/util')

DomView = require('../dom-view').DomView
Templater = require('../../templater/templater').Templater
ListView = require('./list').ListView


class ListEditView extends ListView
  _initialize: ->
    super()
    this.options.childOpts = util.extendNew(this.options.childOpts, { context: this.options.itemContext, list: this.subject })
    this.options.itemContext ?= 'edit'


class ListEditItemTemplate extends Templater
  _binding: ->
    binding = super()
    binding.find('.editItem').render(this.options.app, context: this.options.context).fromSelf()
    binding

class ListEditItem extends DomView
  templateClass: ListEditItemTemplate # you'll have to override anyway.

  _wireEvents: ->
    dom = this.artifact()

    dom.find('> .editRemove').on 'click', (event) =>
      event.preventDefault()
      this.options.list.remove(this.subject)


util.extend(module.exports,
  ListEditView: ListEditView

  ListEditItemTemplate: ListEditItemTemplate
  ListEditItem: ListEditItem
)

