{ Varying, DomView, from, template, find, mutators, Base, List } = require('janus')
{ EnumAttribute } = require('janus').attribute
{ isArray, identity } = require('janus').util

$ = require('../util/dollar')

class ListSelectItemView extends DomView
  @_dom: -> $('
    <div>
      <div class="janus-list-selectItem">
        <button class="janus-list-selectItem-select"></button>
        <div class="janus-list-selectItem-contents"></div>
      </div>
    </div>
  ')
  @_template: template(
    find('.janus-list-selectItem-select').text(from.self().flatMap((view) ->
      view.options.buttonLabel?(view.subject) ? 'Select'
    ))

    find('.janus-list-selectItem').classed('checked', from.self().flatMap((view) ->
      view.options.enum.watchValue().map((value) -> value is view.subject)
    ))
  )

  # much like ListEditItemView again. but again, with a different string literal.
  _render: ->
    wrapper = this.constructor._dom()
    dom = wrapper.children(':first')

    # render our inner contents.
    contentsBinding = this.options.renderItem(mutators.render(from(this.subject)))(dom.find('.janus-list-selectItem-contents'), (x) => this.constructor.point(x, this))

    # now render the bindings actually defined in our own template.
    this._bindings = this.constructor._template(wrapper)((x) => this.constructor.point(x, this))
    this._bindings.push(contentsBinding)

    dom

  _wireEvents: ->
    this.artifact().find('.janus-list-selectItem-select').on('click', => this.options.enum.setValue(this.subject))

# this is a bit of a complicated case because EnumAttribute#value could return
# a Varying[List] so we can't just derive and simply play render context tricks
# like ListEditView (though we do that too).
#
# eventually (TODO) it would be nice to not have the wrapper div. But for now
# it simplifies the problem by quite a bit.
class EnumAttributeListEditView extends DomView
  @_dom: -> $('<div class="janus-enumSelect"/>') # not sure about this class name.
  @_template: template(
    find('div').render(from.self().flatMap((view) ->
      Varying.ly(view.subject.values()).map((values) ->
        # normalize values into a list.
        if !values?
          new List()
        else if isArray(values)
          new List(values)
        else if values.isCollection
          values
        else
          console.error('got an unexpected value for EnumAttribute#values')
          new List()
      )
    )).options(from.self().map((view) ->
      # very very similar to ListEditView but with different default values. could
      # probably be combined.
      ogRenderItem = view.options.renderItem ? identity
      modifiedRenderItem = (render) -> ogRenderItem(render.context('summary'))
      renderWrapper = view.options.renderWrapper ? identity

      {
        renderItem: (render) =>
          renderWrapper(
            render
              .context('select-wrapper')
              .options({ renderItem: modifiedRenderItem, enum: view.subject, buttonLabel: view.options.buttonLabel })
          )
      }
    ))
  )


module.exports = {
  EnumAttributeListEditView: EnumAttributeListEditView,
  ListSelectItemView: ListSelectItemView,
  registerWith: (library) ->
    library.register(Number, ListSelectItemView, context: 'select-wrapper')
    library.register(Boolean, ListSelectItemView, context: 'select-wrapper')
    library.register(String, ListSelectItemView, context: 'select-wrapper')
    library.register(Base, ListSelectItemView, context: 'select-wrapper')
    library.register(EnumAttribute, EnumAttributeListEditView, context: 'edit', attributes: { style: 'list' })
}


