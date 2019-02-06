{ Varying, DomView, from, template, find, mutators, Base, List } = require('janus')
{ Enum } = require('janus').attribute
{ identity } = require('janus').util
{ asList } = require('../util/util')

$ = require('janus-dollar')

ListSelectItemView = class extends DomView.build($('
    <div class="janus-list-selectItem">
      <button class="janus-list-selectItem-select"></button>
      <div class="janus-list-selectItem-contents"></div>
    </div>'), template(

    find('.janus-list-selectItem').classed('checked', from.self().flatMap((view) ->
      view.options.enum.getValue().map((value) -> value is view.subject)))

    find('.janus-list-selectItem-select')
      .text(from.self().flatMap((view) -> view.options.buttonLabel?(view.subject) ? 'Select'))
      .on('click', (_, subject, view) -> view.options.enum.setValue(subject))
  ))

  _render: -> this._doRender(true)

  _attach: (dom) ->
    this._doRender(false)
    return

  _doRender: (immediate) ->
    # much like ListEditItemView again. but again, with a different int literal.
    dom = this.dom()
    contentWrapper = dom.children().eq(1) # faster
    point = this.pointer()

    # render our inner contents.
    contentBinding = this.options.renderItem(mutators.render(from(this.subject)))(contentWrapper, point, immediate)

    # now render the bindings actually defined in our own template.
    this._bindings = this.preboundTemplate(dom, point)
    this._bindings.push(contentBinding)

    dom

# this is a bit of a complicated case because EnumAttribute#value could return
# a Varying[List] so we can't just derive and simply play render context tricks
# like ListEditView (though we do that too).
#
# eventually (TODO) it would be nice to not have the wrapper div. But for now
# it simplifies the problem by quite a bit.
EnumAttributeListEditView = DomView.build($('<div class="janus-enumSelect"/>'), template(
  find('div')
    .render(from.self().flatMap((view) ->
      values = view.subject.values()
      values = values.all.point(view.subject.model.pointer()) if values.all?.point?
      Varying.of(values).map(asList)
    ))
      .options(from.self().map((view) ->
        # very very similar to ListEditView but with different default values. could
        # probably be combined.
        ogRenderItem = view.options.renderItem ? identity
        modifiedRenderItem = (render) -> ogRenderItem(render.context('summary'))
        renderWrapper = view.options.renderWrapper ? identity

        {
          renderItem: (render) => renderWrapper(render
            .context('select-wrapper')
            .options({
              renderItem: modifiedRenderItem,
              enum: view.subject,
              buttonLabel: view.options.buttonLabel
            }))
        }
      ))
))


module.exports = {
  EnumAttributeListEditView: EnumAttributeListEditView,
  ListSelectItemView: ListSelectItemView,
  registerWith: (library) ->
    library.register(Number, ListSelectItemView, context: 'select-wrapper')
    library.register(Boolean, ListSelectItemView, context: 'select-wrapper')
    library.register(String, ListSelectItemView, context: 'select-wrapper')
    library.register(Base, ListSelectItemView, context: 'select-wrapper')
    library.register(Enum, EnumAttributeListEditView, context: 'edit', style: 'list')
}


