{ Model, bind, List, DomView, template, find, from } = require('janus')

$ = require('../dollar')


# these classes are mostly to facilitate the treeviews involved with rendering
# varying debug information.

class LinkedListNode extends Model.build(
    bind('next', from('list').and('idx').all.flatMap((list, idx) ->
      list.length.map((length) -> new LinkedListNode(list, idx + 1) if length > (idx + 1))
    ))
  )

  constructor: (list, idx) -> super({ list, idx })

LinkedListNodeView = DomView.build($('
    <div class="linkedList-node">
      <div class="linkedList-next"/>
      <div class="linkedList-contents"/>
    </div>
  '), template(

    find('.linkedList-contents')
      .render(from('list').and('idx').all.flatMap((list, idx) -> list.at(idx)))
      .context(from.self().map((v) -> v.options.itemContext))

    find('.linkedList-next')
      .render(from('next'))
        .options(from.self().map((v) -> { itemContext: v.options.itemContext }))

      .classed('hasNext', from('next').map((x) -> x?))
  )
)

LinkedListView = DomView.build($('<div class="linkedList"/>'), template(
    find('.linkedList')
      .render(from.self().map((v) -> new LinkedListNode(v.subject, 0)))
      .options(from.self().map((v) -> { itemContext: v.options.itemContext }))
  )
)


module.exports = {
  LinkedListNode
  LinkedListNodeView
  LinkedListView

  registerWith: (library) ->
    library.register(LinkedListNode, LinkedListNodeView)
    library.register(List, LinkedListView, context: 'linked')
}

