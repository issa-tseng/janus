{ DomView, template, find, from } = require('janus')
{ TruncatingLiteral, DateInspector } = require('./inspector')
$ = require('janus-dollar')


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

DateTimeLiteralView = DomView.build($('
  <span class="janus-inspect-entity janus-inspect-date no-panel">
    <span class="entity-title">Date</span>
    <span class="entity-content">
      <span class="date-date"/>T<span class="date-time"/><span class="date-tz"/>
    </span>
  </span>'), template(
  find('.date-date').text(from('target').map((date) -> date.toISODate()))
  find('.date-time').text(from('target').map((date) -> date.toFormat('HH:mm:ss.SSS')))
  find('.date-tz').text(from('target').map((date) -> date.toFormat('ZZ')))
))

module.exports = {
  TruncatingLiteral,
  DateTimeLiteralView,
  registerWith: (library) ->
    library.register(TruncatingLiteral, TruncatingLiteralView)
    library.register(DateInspector, DateTimeLiteralView)
}

