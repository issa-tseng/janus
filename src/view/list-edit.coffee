{ Varying, DomView, mutators, from, template, find, Base, List } = require('janus')

$ = require('janus-dollar')
{ ListView } = require('./list')

# handle move button events.
moveHandler = (direction) -> (event, subject, view) ->
  moveButton = $(event.target)
  return if moveButton.hasClass('disabled')
  view.options.list.move(subject, moveButton.parent().prevAll().length + direction)
  return

ListEditItemView = class extends DomView.build($('
    <div class="janus-list-editItem">
      <button class="janus-list-editItem-moveUp">Move Up</button>
      <button class="janus-list-editItem-moveDown">Move Down</button>
      <button class="janus-list-editItem-remove">Remove</button>
      <div class="janus-list-editItem-dragHandle"></div>
      <div class="janus-list-editItem-contents"></div>
    </div>
  '), template(
    find('.janus-list-editItem-moveUp')
      .classed('disabled', from.self().flatMap((view) -> view.options.list.at(0))
        .and.self().map((view) -> view.subject)
        .all.map((first, item) -> first is item))

      .on('click', moveHandler(-1))

    find('.janus-list-editItem-moveDown')
      .classed('disabled', from.self().flatMap((view) -> view.options.list.at(-1))
        .and.self().map((view) -> view.subject)
        .all.map((last, item) -> last is item))

      .on('click', moveHandler(1))

    find('.janus-list-editItem-remove').on('click', (event, subject, view) ->
      event.preventDefault()
      view.options.list.remove(subject)
    )
  ))

  # TODO: is there some way to do this without breaking into the class?
  _render: -> this._doRender(true)
  _attach: (dom) -> this._doRender(false); return

  # we have to render ourselves, as we need to enable options.renderItem().
  # but, it's really not that bad. we just rely on a mutator anyway.
  _doRender: (immediate) ->
    dom = this.dom()
    content = dom.children().eq(4) # faster
    point = this.pointer()

    # render our inner contents.
    contentBinding = this.options.renderItem(mutators.render(from(this.subject)))(content, point, immediate)

    # now render the bindings actually defined in our own template.
    this._bindings = this.preboundTemplate(dom, point)
    this._bindings.push(contentBinding)

    dom

  _wireEvents: ->
    # handle external move notifications.
    # rather than handle the dragHandle ourselves and impose our opinion on how
    # it should be done, feel free to attach your own library, and all you have
    # to do is trigger 'janus-list-itemMoved' on the dom node that moved.
    this.artifact().on('janus-itemMoved', (event) =>
      return if event.isDefaultPrevented()
      event.preventDefault()
      this.options.list.move(this.subject, $(event.target).prevAll().length)
    )

class ListEditView extends ListView
  dom: -> $('<div class="janus-list janus-list-edit"/>')
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

