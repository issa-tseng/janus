should = require('should')

from = require('../../lib/core/from')
cases = require('../../lib/core/types').from
{ defcase, match, otherwise } = require('../../lib/core/case')
Varying = require('../../lib/core/varying').Varying

id = (x) -> x

should.Assertion.add('val', (->
  this.params = { operator: 'to be a val' }
  this.obj.should.be.an.Object()

  this.obj.map.should.be.a.Function()
  this.obj.flatMap.should.be.a.Function()
  this.obj.and.should.be.a.Function()
  this.obj.all.should.be.an.Object()
), true)

# this only checks (some) default conjunctions! custom-built chainers will have
# a different shape.
should.Assertion.add('conjunction', (->
  this.params = { operator: 'to be a default conjunction' }
  this.obj.should.be.a.Function()
  this.obj.watch.should.be.a.Function()
  this.obj.attribute.should.be.a.Function()
  this.obj.varying.should.be.a.Function()
), true)

should.Assertion.add('terminus', (->
  this.params = { operator: 'to be a terminus' }
  this.obj.should.be.an.Object()

  this.obj.point.should.be.a.Function()
  this.obj.flatMap.should.be.a.Function()
  this.obj.map.should.be.a.Function()
  this.obj.all.should.equal(this.obj)
), true)

should.Assertion.add('varying', (->
  this.params = { operator: 'to be a Varying' }

  this.obj.flatMap.should.be.a.Function()
  this.obj.map.should.be.a.Function()

  this.obj.react.should.be.a.Function()
), true)

describe 'from', ->
  describe 'initial val', ->
    it 'should return a val-looking thing', ->
      from('a').should.be.a.val()

    it 'should contain functions that return val-looking things', ->
      from.watch('b').should.be.a.val()
      from.attribute('b').should.be.a.val()
      from.varying('b').should.be.a.val()

    it 'should not contain function called dynamic', ->
      (from.dynamic?).should.equal(false)

  describe 'val', ->
    it 'should return a val-looking thing on map', ->
      from('a').map(->).should.be.a.val()

    it 'should return a val-looking thing on flatMap', ->
      from('a').flatMap(->).should.be.a.val()

    it 'should return a conjunction-looking thing on and', ->
      from('a').and.should.be.a.conjunction()

    it 'should return a terminus-looking thing on all', ->
      from('a').all.should.be.a.terminus()

  describe 'point', ->
    it 'should return a true varying', ->
      from('a').all.point(->).isVarying.should.equal(true)

    it 'should execute a pointing function with the case', ->
      args = []

      from('a')
        .and.watch('b')
        .and.attribute('d')
        .and.varying('e')
        .all.point((x) -> args.push(x); x)

      args[0].should.be.an.instanceof(cases.dynamic.type)
      args[0].get().should.equal('a')

      args[1].should.be.an.instanceof(cases.watch.type)
      args[1].get().should.equal('b')

      args[2].should.be.an.instanceof(cases.attribute.type)
      args[2].get().should.equal('d')

      args[3].should.be.an.instanceof(cases.varying.type)
      args[3].get().should.equal('e')

    it 'should only point for things that have not resolved to varying', ->
      { dynamic, watch, definition, varying } = cases

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
    it 'should be called with unresolved applicants', ->
      called = false

      v = from('a')
        .and.watch('b')
        .all.map (xs...) ->
          called = true

          xs.length.should.equal(2)

          xs[0].should.be.a.Function()
          xs[1].should.be.a.Function()

      called.should.equal(false)

      v.point().react(->)
      called.should.equal(true)

    it 'should be called with resolved applicants', ->
      { dynamic, watch, definition, varying } = cases
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

      v.react(->)
      called.should.equal(true)

    it 'should not flatten the result', ->
      result = null
      from('a').all.map(-> new Varying(2)).point().react((x) -> result = x)
      result.isVarying.should.equal(true)
      result.get().should.equal(2)

  describe 'flatMapAll', ->
    # very condensed test because the mapAll tests should cover this.
    it 'should be called with appropriate applicants', ->
      { dynamic, watch, definition, varying } = cases
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
          xs[1].should.be.a.Function()
        )

      v.react(->)
      called.should.equal(true)

    it 'should flatten the result', ->
      result = null
      from('a').all.point().flatMap(-> new Varying(3)).react((x) -> result = x)
      result.should.equal(3)

  describe 'direct reaction', ->
    it 'should apply applicants as args', ->
      { dynamic, watch, definition, varying } = cases
      result = null

      v = from('a').and('b').and('c')
        .all.point(match(
          dynamic (x) -> new Varying(x)
          otherwise id
        )).react((xs...) -> result = xs)

      result.should.eql([ 'a', 'b', 'c' ])

    it 'should return a single applicant as the argument absent an allmapper', ->
      { dynamic, watch, definition, varying } = cases
      result = null

      v = from('a')
        .all.point(match(
          dynamic (x) -> new Varying(x)
          otherwise id
        )).react((x) -> result = x)

      result.should.equal('a')

  describe 'inline map', ->
    it 'should apply a map after point resolution', ->
      { dynamic } = cases

      result = null
      from('a').map((x) -> x + 'b')
        .all.point(match(
          dynamic (xs) -> new Varying(xs[0])
          otherwise ->
        ))
        .map(id).react((x) -> result = x)

      result.should.equal('ab')

    it 'should apply chained maps in the right order', ->
      { dynamic } = cases

      result = null
      from('a').map((x) -> x + 'b').map((x) -> x + 'c')
        .all.point(match(
          dynamic (xs) -> new Varying(xs[0])
          otherwise ->
        ))
        .map(id).react((x) -> result = x)

      result.should.equal('abc')

    it 'should not flatten', -> # gh41
      { dynamic } = cases

      result = null
      v = new Varying('b')
      from('a').map((x) -> v)
        .all.point(match(
          dynamic (x) -> new Varying(x)
          otherwise ->
        ))
        .react((x) -> result = x)

      result.should.equal(v)

  describe 'inline flatmap', ->
    it 'should apply a flatMap after point resolution', ->
      { dynamic } = cases

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
        .map(id).react((x) -> result = x)

      result.should.equal('ab')

      v.set('cd')
      result.should.equal('cd')

  describe 'inline watch', ->
    it 'should apply as a flatMap after point resolution', ->
      { dynamic } = cases

      called = null
      result = null
      iv = new Varying(2)
      from('a').watch('myattr')
        .all.point(match(
          dynamic -> new Varying({ watch: (x) -> called = x; iv })
          otherwise ->
        ))
        .map(id).react((x) -> result = x)

      called.should.equal('myattr')
      result.should.equal(2)

  describe 'inline attribute', ->
    it 'should apply as a map after point resolution', ->
      { dynamic } = cases

      called = null
      result = null
      from('a').attribute('myattr')
        .all.point(match(
          dynamic -> new Varying({ attribute: (x) -> called = x; 42 })
          otherwise ->
        ))
        .map(id).react((x) -> result = x)

      called.should.equal('myattr')
      result.should.equal(42)

  describe 'inline pipe', ->
    it 'should apply a pipe after point resolution', ->
      { dynamic } = cases

      result = null
      from('a').pipe((v) -> v.map((x) -> x + 'b'))
        .all.point(match(
          dynamic (xs) -> new Varying(xs[0])
          otherwise ->
        ))
        .map(id).react((x) -> result = x)

      result.should.equal('ab')

  describe 'inline asVarying', ->
    { dynamic } = cases
    idmatch = match(
      dynamic (x) -> x
      otherwise ->
    )

    it 'should supply a varying parameter to all-map', ->

      v = new Varying(1)
      result = null
      from(v).asVarying()
        .all.point(idmatch).map(id).react((x) -> result = x)

      result.isVarying.should.equal(true)

    it 'should provide the correct inner value', ->
      { dynamic } = cases

      v = new Varying(1)
      results = []
      from(v).map((x) -> x * 2).asVarying()
        .all.point(idmatch).map(id).react((x) -> x.react((y) -> results.push(y)))

      v.set(4)
      results.should.eql([ 2, 8 ])

    it 'should supply a varying parameter to inline-map', ->
      { dynamic } = cases

      v = new Varying(1)
      result = null
      results = []
      from(v).asVarying().flatMap((x) -> result = x; x)
        .all.point(idmatch).map(id).react((x) -> results.push(x))

      result.isVarying.should.equal(true)
      v.set(3)
      results.should.eql([ 1, 3 ])

  describe 'builder', ->
    it 'should accept custom cases as intermediate methods/applicants', ->
      { alpha, beta, gamma } = custom = defcase('alpha', 'beta', 'gamma')

      v = from.build(custom).alpha('one')
        .and.beta('two')
        .and.gamma('three')
        .all.point(match(
          alpha (x) -> new Varying("a#{x}")
          beta (x) -> new Varying("b#{x}")
          gamma (x) -> new Varying("c#{x}")
        )).flatMap((xs...) -> xs.join(' '))

      result = null
      v.react((x) -> result = x)
      result.should.equal('aone btwo cthree')

    it 'should use the dynamic case if present', ->
      { dynamic, other } = custom = defcase('dynamic', 'other')

      v = from.build(custom)('one')
        .and.other('two')
        .all.point(match(
          dynamic (x) -> new Varying("a#{x}")
          other (x) -> new Varying("b#{x}")
        )).flatMap((xs...) -> xs.join(' '))

      result = null
      v.react((x) -> result = x)
      result.should.equal('aone btwo')

    it 'should not use the dynamic case if not present', ->
      { a, b } = custom = defcase('a', 'b')

      from.build(custom).should.not.be.a.Function()

  describe 'deferred point calling order', ->
    it 'should work with non-immediate react', ->
      { dynamic } = cases

      f = from('a').and('b')
        .all.map((a, b) -> a + b)

      iv = new Varying('c')
      v = f.point(match(
        dynamic (x) -> iv.flatMap((y) -> new Varying(x + y))
        otherwise ->
      ))

      result = null
      v.react(false, (x) -> result = x)
      (result is null).should.equal(true)

      iv.set('d')
      result.should.equal('adbd')

    it 'should work with react', ->
      { dynamic } = cases

      f = from('a').and('d')
        .all.map((a, b) -> a + b)

      iv = new Varying('c')
      v = f.point(match(
        dynamic (x) -> iv.flatMap((y) -> new Varying(x + y))
        otherwise ->
      ))

      result = null
      v.react((x) -> result = x)
      result.should.equal('acdc')

