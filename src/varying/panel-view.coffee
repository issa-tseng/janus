{ Varying, Model, attribute, bind, DomView, template, find, from } = require('janus')
$ = require('janus-dollar')
{ DateTime } = require('luxon')

{ exists } = require('../util')
{ WrappedFunction } = require('../function/inspector')
{ WrappedVarying, Reaction } = require('./inspector')
{ inspect } = require('../inspect')


################################################################################
# REACTION VIEW (list)

ReactionVM = Model.build(
  bind('target-inspector', from('view').map((v) -> v.closest(WrappedVarying).first().get_().subject))
  bind('snapshot', from('target-inspector').get('id').and.subject()
    .all.flatMap((id, rxn) -> rxn.get("tree.#{id}")))
  bind('changed', from('snapshot').get('changed'))
)

ReactionView = DomView.withOptions({ viewModelClass: ReactionVM }).build(
  $('<div class="reaction"><span class="rxn-value"/></div>'),
  template(
    find('.reaction')
      .classed('target-changed', from.vm('changed'))
      .classed('target-unchanged', from.vm('changed').map((x) -> !x))
    find('.rxn-value')
      .render(from.vm('snapshot').flatMap(((vi) -> vi?.get('new_value').map(inspect))))
))

################################################################################
# VARYING DELTA ("x -> y") VIEW

VaryingDeltaView = DomView.build($('
    <span class="varying-delta">
      <span class="value"/>
      <span class="delta">
        <span class="separator"/>
        <span class="new-value"/>
      </span>
    </span>
  '), template(

    find('.value').render(from('value').all.map(inspect))
    find('.new-value').render(from('new_value').map(inspect))

    find('.varying-delta').classed('has-delta', from('changed'))
  )
)

################################################################################
# VARYING NODE VIEW
# TODO: feels like there should be a lighter weight approach.
# TODO: should this really have an entity class?

VaryingNodeView = DomView.build($('
  <div class="varying-node janus-inspect-entity">
    <div class="inner-marker"/>
    <div class="value-marker"/>
  </div>
'), template())

################################################################################
# VARYING TREE VIEW

VaryingTreeView = DomView.build($('
    <div class="varying-tree">
      <div class="main">
        <div class="node"/>
        <div class="valueBlock"/>
      </div>
      <div class="aux">
        <div class="varying-tree-inner varying-tree-innerNew"/>
        <div class="varying-tree-inner varying-tree-innerMain"/>
        <div class="mapping"><span>λ</span></div>
      </div>
      <div class="varying-tree-nexts"/>
    </div>
  '), template(

    find('.varying-tree')
      .classed('derived', from('derived'))
      .classed('flattened', from('flattened'))
      .classed('mapped', from('mapped'))
      .classed('reducing', from('reducing'))

      .classed('hasObservations', from('observations').flatMap((os) -> os.nonEmpty()))
      .classed('hasValue', from('value').map(exists))
      .classed('hasInner', from('inner').and('new_inner').all.map((x, y) -> x? or y?))

    # TODO: ehhh on these context names?
    find('.node').render(from.subject()).context('node')
    find('.valueBlock').render(from.subject()).context('delta')

    find('.mapping').on('mouseenter', (event, wrapped, view) ->
      args = []
      for a in wrapped.get_('applicants').list
        wa = WrappedVarying.hijack(a)
        args.push(wa.get_('new_value') ? wa.get_('value'))
      wf = new WrappedFunction(wrapped.varying._f, args)
      view.options.app.flyout?($(event.target), wf, 'panel')
    )

    find('.varying-tree-innerNew')
      .classed('hasNewInner', from('new_inner').map(exists))
      .render(from('new_inner').map((v) -> WrappedVarying.hijack(v) if v?)).context('tree')
    find('.varying-tree-innerMain')
      .classed('hasMainInner', from('inner').map(exists))
      .render(from('inner').map((v) -> WrappedVarying.hijack(v) if v?)).context('tree')
    find('.varying-tree-nexts')
      .render(from('applicants').map((xs) -> xs?.map(WrappedVarying.hijack)))
        .context('linked').options( itemContext: 'tree' )
  )
)


################################################################################
# VARYING PANEL

class VaryingPanel extends Model.build(
  attribute('selected-rxn', class extends attribute.Enum
    nullable: true
    values: -> from.subject('reactions')
    default: -> null
  )
  bind('active-rxn', from('hovered-rxn').and('selected-rxn').all.map((h, s) -> h ? s))
)

VaryingView = DomView.withOptions({ viewModelClass: VaryingPanel }).build($('
    <div class="janus-inspect-panel janus-inspect-varying">
      <div class="panel-title">
        <span class="varying-title"/> #<span class="varying-id"/>
        <button class="janus-inspect-pin" title="Pin"/>
      </div>
      <div class="panel-derivation">
        Given by <span class="varying-owner"/>
        via .<span class="derivation-method"/><span class="derivation-arg"/>
      </div>
      <div class="panel-content">
        <div class="varying-reaction-bar">
          <label>Reactions</label>
          <div class="varying-reactions"/>
          <span class="varying-reactions-none">(none tracked)</span>
        </div>
        <div class="varying-snapshot">
          Change snapshot at <span class="varying-snapshot-time"/>
          <button class="varying-snapshot-close" title="Close Snapshot"/>
        </div>
        <div class="varying-inert">
          Inert (no observers).
          <a class="varying-observe" href="#react">Observe now</a>.
        </div>
        <div class="varying-tree"/>
      </div>
    </div>
  '), template(
    find('.janus-inspect-varying').classed('selected-rxn', from.vm('selected-rxn').map(exists))
    find('.varying-title').text(from('title'))
    find('.varying-id').text(from('id'))

    find('.panel-derivation').classed('hide', from('owner').map((x) -> !x?))
    find('.varying-owner').render(from('owner').map(inspect))
    find('.derivation-method').text(from('derivation').get('method'))
    find('.derivation-arg')
      .classed('has-arg', from('derivation').get('arg').map(exists))
      .render(from('derivation').get('arg').map(inspect))

    find('.varying-reactions')
      .classed('has-reactions', from('reactions').flatMap((rs) -> rs.nonEmpty()))
      .render(from.vm().attribute('selected-rxn'))
        .context('edit').criteria( style: 'list' )
      .on('mouseover', '.reaction', (event, s, { viewModel }) ->
        viewModel.set('hovered-rxn', $(event.currentTarget).view().subject))
      .on('mouseleave', (event, s, { viewModel }) -> viewModel.unset('hovered-rxn'))

    find('.varying-snapshot-time').text(from.vm('active-rxn').get('at').map((t) ->
      DateTime.fromJSDate(t).toFormat("HH:mm:ss.SSS")))
    find('.varying-snapshot-close').on('click', (e, s, { vm }) -> vm.unset('selected-rxn'))

    find('.varying-inert').classed('hide', from('observations').flatMap((obs) -> obs?.nonEmpty()))
    find('.varying-observe').on('click', (event, subject) ->
      event.preventDefault()
      subject.varying.react()
    )

    find('.varying-tree').render(from.subject().and.vm('active-rxn').all.flatMap((wv, ar) ->
      if ar? then wv.get('id').flatMap((id) -> ar.get("tree.#{id}")) else wv
    )).context('tree')
  )
)

module.exports = {
  VaryingDeltaView
  VaryingTreeView
  VaryingView
  ReactionView

  registerWith: (library) ->
    library.register(WrappedVarying, VaryingDeltaView, context: 'delta')
    library.register(WrappedVarying, VaryingNodeView, context: 'node')
    library.register(WrappedVarying, VaryingTreeView, context: 'tree')
    library.register(WrappedVarying, VaryingView, context: 'panel')
    library.register(Reaction, ReactionView)
}

