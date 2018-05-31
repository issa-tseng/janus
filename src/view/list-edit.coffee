{ Varying, DomView, mutators, from, template, find, Base, List } = require('janus')

$ = require('../util/dollar')
{ ListView } = require('./list')

# handle move button events.
moveHandler = (direction) -> (event, subject, view, dom) ->
  event.preventDefault()
  moveButton = $(event.target)
  return if moveButton.hasClass('disabled')

  # update the internal model.
  li = moveButton.closest('li')
  dest = li.prevAll().length + direction
  view.options.list.move(subject, dest)

  # List#move does not emit added/removed so manipulate the dom ourselves.
  parent = li.parent()
  li.detach()
  children = parent.children()
  if dest is children.length
    parent.append(li)
  else
    children.eq(dest).before(li)

ListEditItemView = class extends DomView.build($('
    <div class="janus-list-editItem">
      <a class="janus-list-editItem-moveUp">Move Up</a>
      <a class="janus-list-editItem-moveDown">Move Down</a>
      <a class="janus-list-editItem-remove">Remove</a>
      <div class="janus-list-editItem-dragHandle"></div>
      <div class="janus-list-editItem-contents"></div>
    </div>
  '), template(
    find('.janus-list-editItem-moveUp')
      .classed('disabled', from.self().flatMap((view) -> view.options.list.watchAt(0))
        .and.self().map((view) -> view.subject)
        .all.map((first, item) -> first is item))

      .on('click', moveHandler(-1))

    find('.janus-list-editItem-moveDown')
      .classed('disabled', from.self().flatMap((view) -> view.options.list.watchAt(-1))
        .and.self().map((view) -> view.subject)
        .all.map((last, item) -> last is item))

      .on('click', moveHandler(1))

    find('.janus-list-editItem-remove').on('click', (event, subject, view) ->
      event.preventDefault()
      view.options.list.remove(subject)
    )
  ))

  # we have to render ourselves, as we need to enable options.renderItem().
  # but, it's really not that bad. we just rely on a mutator anyway.
  # TODO: is there some way to do this without breaking into the class?
  _render: ->
    dom = this.dom()
    content = dom.children().eq(4) # faster
    point = this.pointer()

    # render our inner contents.
    contentBinding = this.options.renderItem(mutators.render(from(this.subject)))(content, point)

    # now render the bindings actually defined in our own template.
    this._bindings = this.preboundTemplate(dom, point)
    this._bindings.push(contentBinding)

    dom

  _wireEvents: ->
    # handle external move notifications.
    # rather than handle the dragHandle ourselves and impose our opinion on how
    # it should be done, feel free to attach your own library, and all you have
    # to do is trigger 'janus-list-itemMoved' on the dom node that moved.
    this.artifact().closest('li').on('janus-itemMoved', (event) =>
      return if event.isDefaultPrevented()
      event.preventDefault()
      this.options.list.move(this.subject, $(event.target).prevAll().length)
    )

class ListEditView extends ListView
  dom: -> $('<ul class="janus-list janus-list-edit"/>')
  _initialize: ->
    super()

    # the magic here is in this shuffle: we save off the requested renderItem,
    # shunt it onto the wrapper child we request instead (which itself may be
    # overridden using renderWrapper), and default the child to an edit context
    # by default. (we also provide a reference to the subject list)
    oldRenderItem = this.options.renderItem
    modifiedRenderItem = (render) -> oldRenderItem(render.context('edit')) # default to edit
    this.options.renderWrapper ?= (x) -> x
    this.options.renderItem = (render) =>
      this.options.renderWrapper(
        render
          .context('edit-wrapper')
          .options({ renderItem: modifiedRenderItem, list: this.subject })
      )

module.exports = {
  ListEditItemView,
  ListEditView,
  registerWith: (library) ->
    # TODO: eventually possibly allow '*' or something.
    library.register(Number, ListEditItemView, context: 'edit-wrapper')
    library.register(Boolean, ListEditItemView, context: 'edit-wrapper')
    library.register(String, ListEditItemView, context: 'edit-wrapper')
    library.register(Base, ListEditItemView, context: 'edit-wrapper')
    library.register(List, ListEditView, context: 'edit')
}

