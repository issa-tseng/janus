{ floor } = Math
{ DomView, template, find, from, Model, bind, dēfault } = require('janus')
$ = require('janus-dollar')

TruncatingLiteral = Model.build(
  # expects string: String

  # skipping use of BooleanAttribute for now to keep the html classes consistent.
  # eventually the stdlib button renderer should take custom classes.
  dēfault('truncate', true)

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

TruncatingLiteralView = DomView.build($('
  <span class="janus-inspect-entity janus-literal">
    <span class="literal-content"/>
    <button class="entity-more">&hellip;<span class="entity-more-count"/> more</button>
  </span>'), template(

  find('.literal-content').text(from('string').and('truncate')
    .all.map((str, truncate) -> if truncate then str.slice(0, 300) else str))

  find('.entity-more-count').text(from('more_count'))

  find('.entity-more')
    .classed('has-more', from('truncate'))
    .on('click', (_, subject) -> subject.set('truncate', false))
))

module.exports = {
  TruncatingLiteral,
  registerWith: (library) ->
    library.register(TruncatingLiteral, TruncatingLiteralView)
}

