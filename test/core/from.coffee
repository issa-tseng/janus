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
  this.obj.watch.should.be.a.Function
  this.obj.resolve.should.be.a.Function
  this.obj.attribute.should.be.a.Function
  this.obj.varying.should.be.a.Function
), true)

should.Assertion.add('terminus', (->
  this.params = { operator: 'to be a terminus' }
  this.obj.should.be.a.Function

  this.obj.point.should.be.a.Function
  this.obj.flatMap.should.be.a.Function
  this.obj.map.should.be.a.Function
), true)

should.Assertion.add('varying', (->
  this.params = { operator: 'to be a Varying' }

  this.obj.flatMap.should.be.a.Function
  this.obj.map.should.be.a.Function

  this.obj.react.should.be.a.Function
  this.obj.reactNow.should.be.a.Function
), true)

describe 'from', ->
  describe 'initial val', ->
    it 'should return a val-looking thing', ->
      from('a').should.be.a.val

    it 'should contain functions that return val-looking things', ->
      from.watch('b').should.be.a.val
      from.resolve('b').should.be.a.val
      from.attribute('b').should.be.a.val
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
        .and.watch('b')
        .and.resolve('c')
        .and.attribute('d')
        .and.varying('e')
        .all.point((x) -> args.push(x); x)

      args[0].should.eql('dynamic')
      args[0].value.should.equal('a')

      args[1].should.eql('watch')
      args[1].value.should.equal('b')

      args[2].should.eql('resolve')
      args[2].value.should.equal('c')

      args[3].should.eql('attribute')
      args[3].value.should.equal('d')

      args[4].should.eql('varying')
      args[4].value.should.equal('e')

    it 'should only point for things that have not resolved to varying', ->
      { dynamic, watch, resolve, definition, varying } = from.default

      count = 0
      incr = (f) -> (args...) -> count += 1; f(args...)

      f1 = from('a')
        .and.watch('b')
        .all.point(match(
          dynamic incr (xs...) -> new Varying()
          otherwise incr id
        ))

      count.should.equal(2)

      f2 = f1.point(match(
        watch incr (xs...) -> new Varying()
        otherwise incr id
      ))

      count.should.equal(3)

      f2.point(match(
        otherwise incr id
      ))

      count.should.equal(3)

  describe 'mapAll', ->
    it 'should return a Varying-looking thing', ->
      from('a').and('b').all.map(->).should.be.a.varying

    it 'should be called with unresolved applicants', ->
      called = false

      v = from('a')
        .and.watch('b')
        .all.map (xs...) ->
          called = true

          xs.length.should.equal(2)

          xs[0].should.eql('dynamic')
          xs[1].should.eql('watch')

      called.should.be.false

      v.reactNow(->)
      called.should.be.true

    it 'should be called with resolved applicants', ->
      { dynamic, watch, resolve, definition, varying } = from.default
      called = false

      v = from('a')
        .and.watch('b')
        .all.point(match(
          dynamic (x) -> new Varying("dynamic: #{x}")
          watch (x) -> new Varying("watch: #{x}")
          otherwise -> null
        )).map((xs...) ->
          called = true

          xs.length.should.equal(2)

          xs[0].should.equal('dynamic: a')
          xs[1].should.equal('watch: b')
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
      { dynamic, watch, resolve, definition, varying } = from.default
      called = false

      v = from('a')
        .and.watch('b')
        .all.point(match(
          dynamic (x) -> new Varying("dynamic: #{x}")
          otherwise id
        )).flatMap((xs...) ->
          called = true

          xs.length.should.equal(2)

          xs[0].should.equal('dynamic: a')

          xs[1].should.eql('watch')
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

  describe 'deferred point calling order', ->
    it 'should work with react', ->
      { dynamic } = from.default

      f = from('a').and('b')
        .all.map((a, b) -> a + b)

      iv = new Varying('c')
      v = f.point(match(
        dynamic (x) -> iv.flatMap((y) -> new Varying(x + y))
        otherwise ->
      ))

      result = null
      v.react((x) -> result = x)
      (result is null).should.be.true

      iv.set('d')
      result.should.equal('adbd')

    it 'should work with reactNow', ->
      { dynamic } = from.default

      f = from('a').and('d')
        .all.map((a, b) -> a + b)

      iv = new Varying('c')
      v = f.point(match(
        dynamic (x) -> iv.flatMap((y) -> new Varying(x + y))
        otherwise ->
      ))

      result = null
      v.reactNow((x) -> result = x)
      result.should.equal('acdc')

