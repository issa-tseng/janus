should = require('should')

from = require('../../lib/core/from')
{ caseSet, match, otherwise } = require('../../lib/core/case')
Varying = require('../../lib/core/varying').Varying

id = (x) -> x

should.Assertion.add('val', (->
  this.params = { operator: 'to be a val' }
  this.obj.should.be.an.Object

  this.obj.map.should.be.a.Function
  this.obj.flatMap.should.be.a.Function
  this.obj.and.should.be.a.Function
  this.obj.all.should.be.a.Function
), true)

# this only checks default conjunctions! custom-built chainers will have a
# different shape.
should.Assertion.add('conjunction', (->
  this.params = { operator: 'to be a default conjunction' }
  this.obj.should.be.a.Function
  this.obj.attr.should.be.a.Function
  this.obj.definition.should.be.a.Function
  this.obj.varying.should.be.a.Function
), true)

should.Assertion.add('terminus', (->
  this.params = { operator: 'to be a terminus' }
  this.obj.should.be.a.Function

  this.obj.point.should.be.a.Function
  this.obj.flatMap.should.be.a.Function
  this.obj.map.should.be.a.Function
), true)

describe.only 'from', ->
  describe 'initial val', ->
    it 'should return a val-looking thing', ->
      from('a').should.be.a.val

    it 'should contain functions that return val-looking things', ->
      from.attr('b').should.be.a.val
      from.definition('b').should.be.a.val
      from.varying('b').should.be.a.val

    it 'should not contain function called dynamic', ->
      (from.dynamic?).should.be.false

  describe 'val', ->
    it 'should return a val-looking thing on map', ->
      from('a').map(->).should.be.a.val

    it 'should return a val-looking thing on flatMap', ->
      from('a').flatMap(->).should.be.a.val

    it 'should return a conjunction-looking thing on and', ->
      from('a').and.should.be.a.conjuction

    it 'should return a terminus-looking thing on all', ->
      from('a').all.should.be.a.terminus

  describe 'point', ->
    it 'should return a terminus-looking thing', ->
      from('a').all.point(->).should.be.a.terminus

    it 'should execute a pointing function with the case', ->
      args = []

      from('a')
        .and.attr('b', 'c')
        .and.definition('d', 'e')
        .and.varying('f')
        .all.point((x) -> args.push(x); x)

      args[0].should.eql('dynamic')
      args[0].value.should.eql([ 'a' ])

      args[1].should.eql('attr')
      args[1].value.should.eql([ 'b', 'c' ])

      args[2].should.eql('definition')
      args[2].value.should.eql([ 'd', 'e' ])

      args[3].should.eql('varying')
      args[3].value.should.eql('f')

    it 'should only point for things that have not resolved to varying', ->
      { dynamic, attr, definition, varying } = from.default

      count = 0
      incr = (f) -> (args...) -> count += 1; f(args...)

      f1 = from('a')
        .and.attr('b', 'c', 'd')
        .all.point(match(
          dynamic incr (xs...) -> new Varying()
          otherwise incr id
        ))

      count.should.equal(2)

      f2 = f1.point(match(
        attr incr (xs...) -> new Varying()
        otherwise incr id
      ))

      count.should.equal(3)

      f2.point(match(
        otherwise incr id
      ))

      count.should.equal(3)

  describe 'mapAll', ->
    it 'should return a Varying', ->
      from('a').and('b').all.map(->).isVarying.should.be.true

    it 'should be called with unresolved applicants', ->
      called = false

      v = from('a')
        .and.attr('b')
        .all.map (xs...) ->
          called = true

          xs.length.should.equal(2)

          xs[0].should.eql('dynamic')
          xs[1].should.eql('attr')

      called.should.be.false

      v.reactNow(->)
      called.should.be.true

    it 'should be called with resolved applicants', ->
      { dynamic, attr, definition, varying } = from.default
      called = false

      v = from('a')
        .and.attr('b')
        .all.point(match(
          dynamic (x) -> new Varying("dynamic: #{x}")
          attr (x) -> new Varying("attr: #{x}")
          otherwise -> null
        )).map((xs...) ->
          called = true

          xs.length.should.equal(2)

          xs[0].should.equal('dynamic: a')
          xs[1].should.equal('attr: b')
        )

      v.reactNow(->)
      called.should.be.true

    it 'should not flatten the result', ->
      result = null
      from('a').all.map(-> new Varying(2)).reactNow((x) -> result = x)
      result.isVarying.should.be.true
      result.get().should.equal(2)

  describe 'flatMapAll', ->
    # very condensed test because the mapAll tests should cover this.
    it 'should be called with appropriate applicants', ->
      { dynamic, attr, definition, varying } = from.default
      called = false

      v = from('a')
        .and.attr('b')
        .all.point(match(
          dynamic (x) -> new Varying("dynamic: #{x}")
          otherwise id
        )).flatMap((xs...) ->
          called = true

          xs.length.should.equal(2)

          xs[0].should.equal('dynamic: a')

          xs[1].should.eql('attr')
        )

      v.reactNow(->)
      called.should.be.true

    it 'should flatten the result', ->
      result = null
      from('a').all.flatMap(-> new Varying(3)).reactNow((x) -> result = x)
      result.should.equal(3)

  describe 'inline map', ->
    it 'should apply a map after point resolution', ->
      { dynamic } = from.default

      result = null
      from('a').map((x) -> x + 'b')
        .all.point(match(
          dynamic (xs) -> new Varying(xs[0])
          otherwise ->
        ))
        .map(id).reactNow((x) -> result = x)

      result.should.equal('ab')

    it 'should apply chained maps in the right order', ->
      { dynamic } = from.default

      result = null
      from('a').map((x) -> x + 'b').map((x) -> x + 'c')
        .all.point(match(
          dynamic (xs) -> new Varying(xs[0])
          otherwise ->
        ))
        .map(id).reactNow((x) -> result = x)

      result.should.equal('abc')

  describe 'inline flatmap', ->
    it 'should apply a flatMap after point resolution', ->
      { dynamic } = from.default

      # we have to do a v ?= here because the pure function gets called twice
      # assuming no side-effects, and therefore the ref we side-effect out gets
      # blasted the second time through.
      result = null
      v = null
      from('a').flatMap((x) -> v ?= new Varying(x + 'b'))
        .all.point(match(
          dynamic (xs) -> new Varying(xs[0])
          otherwise ->
        ))
        .map(id).reactNow((x) -> result = x)

      result.should.equal('ab')

      v.set('cd')
      result.should.equal('cd')

  describe 'builder', ->
    it 'should accept custom cases as intermediate methods/applicants', ->
      { alpha, beta, gamma } = custom = caseSet('alpha', 'beta', 'gamma')

      v = from.build(custom).alpha('one')
        .and.beta('two')
        .and.gamma('three')
        .all.point(match(
          alpha (x) -> new Varying("a#{x}")
          beta (x) -> new Varying("b#{x}")
          gamma (x) -> new Varying("c#{x}")
        )).flatMap((xs...) -> xs.join(' '))

      result = null
      v.reactNow((x) -> result = x)
      result.should.equal('aone btwo cthree')

    it 'should use the dynamic case if present', ->
      { dynamic, other } = custom = caseSet('dynamic', 'other')

      v = from.build(custom)('one')
        .and.other('two')
        .all.point(match(
          dynamic (x) -> new Varying("a#{x}")
          other (x) -> new Varying("b#{x}")
        )).flatMap((xs...) -> xs.join(' '))

      result = null
      v.reactNow((x) -> result = x)
      result.should.equal('aone btwo')

    it 'should not use the dynamic case if not present', ->
      { a, b } = custom = caseSet('a', 'b')

      from.build(custom).should.not.be.a.Function

