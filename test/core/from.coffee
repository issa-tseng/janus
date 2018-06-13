should = require('should')

from = require('../../lib/core/from')
{ defcase, match, otherwise } = require('../../lib/core/case')
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
  this.obj.reactLater.should.be.a.Function
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

      args[0].type.should.eql('dynamic')
      args[0].value.should.equal('a')

      args[1].type.should.eql('watch')
      args[1].value.should.equal('b')

      args[2].type.should.eql('resolve')
      args[2].value.should.equal('c')

      args[3].type.should.eql('attribute')
      args[3].value.should.equal('d')

      args[4].type.should.eql('varying')
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

  describe 'plain', ->
    it 'should automatically resolve Varyings', ->
      v1 = new Varying('a')
      v2 = new Varying('b')

      result = null
      from(v1).and.varying(v2).all.plain().map((x, y) -> x + y).react((x) -> result = x)
      result.should.equal('ab')

      v1.set('x')
      result.should.equal('xb')

      v2.set('y')
      result.should.equal('xy')

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

          xs[0].type.should.eql('dynamic')
          xs[1].type.should.eql('watch')

      called.should.be.false

      v.react(->)
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

      v.react(->)
      called.should.be.true

    it 'should not flatten the result', ->
      result = null
      from('a').all.map(-> new Varying(2)).react((x) -> result = x)
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

          xs[1].type.should.eql('watch')
        )

      v.react(->)
      called.should.be.true

    it 'should flatten the result', ->
      result = null
      from('a').all.flatMap(-> new Varying(3)).react((x) -> result = x)
      result.should.equal(3)

  describe 'direct reaction', ->
    it 'should return applicants as an array absent an allmapper', ->
      { dynamic, watch, resolve, definition, varying } = from.default
      result = null

      v = from('a').and('b').and('c')
        .all.point(match(
          dynamic (x) -> new Varying(x)
          otherwise id
        )).react((x) -> result = x)

      result.should.eql([ 'a', 'b', 'c' ])

    it 'should return a single applicant as the argument absent an allmapper', ->
      { dynamic, watch, resolve, definition, varying } = from.default
      result = null

      v = from('a')
        .all.point(match(
          dynamic (x) -> new Varying(x)
          otherwise id
        )).react((x) -> result = x)

      result.should.equal('a')

  describe 'inline map', ->
    it 'should apply a map after point resolution', ->
      { dynamic } = from.default

      result = null
      from('a').map((x) -> x + 'b')
        .all.point(match(
          dynamic (xs) -> new Varying(xs[0])
          otherwise ->
        ))
        .map(id).react((x) -> result = x)

      result.should.equal('ab')

    it 'should apply chained maps in the right order', ->
      { dynamic } = from.default

      result = null
      from('a').map((x) -> x + 'b').map((x) -> x + 'c')
        .all.point(match(
          dynamic (xs) -> new Varying(xs[0])
          otherwise ->
        ))
        .map(id).react((x) -> result = x)

      result.should.equal('abc')

    it 'should not flatten', -> # gh41
      { dynamic } = from.default

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
        .map(id).react((x) -> result = x)

      result.should.equal('ab')

      v.set('cd')
      result.should.equal('cd')

  describe 'inline watch', ->
    it 'should apply as a flatMap after point resolution', ->
      { dynamic } = from.default

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

    it 'should use the fallback value if the obj is null', ->
      { dynamic } = from.default

      result = null
      from('a').watch('myattr', 'no luck')
        .all.point(match(
          dynamic -> new Varying()
          otherwise ->
        ))
        .map(id).react((x) -> result = x)

      result.should.equal('no luck')

  describe 'inline resolve', ->
    it 'should apply as a flatMap after point resolution', ->
      { dynamic, app } = from.default

      iv = new Varying(2)
      myApp = {}
      result = null
      calledAttr = calledApp = null
      from('a').resolve('myattr')
        .all.point(match(
          dynamic -> new Varying({ resolve: (attr, app) -> calledAttr = attr; calledApp = app; iv })
          app -> new Varying(myApp)
          otherwise ->
        ))
        .map(id).react((x) -> result = x)

      result.should.equal(2)
      calledAttr.should.equal('myattr')
      calledApp.should.equal(myApp)

  describe 'inline attribute', ->
    it 'should apply as a map after point resolution', ->
      { dynamic } = from.default

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
      { dynamic } = from.default

      result = null
      from('a').pipe((v) -> v.map((x) -> x + 'b'))
        .all.point(match(
          dynamic (xs) -> new Varying(xs[0])
          otherwise ->
        ))
        .map(id).react((x) -> result = x)

      result.should.equal('ab')

  describe 'inline asVarying', ->
    { dynamic } = from.default
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
      { dynamic } = from.default

      v = new Varying(1)
      results = []
      from(v).map((x) -> x * 2).asVarying()
        .all.point(idmatch).map(id).react((x) -> x.react((y) -> results.push(y)))

      v.set(4)
      results.should.eql([ 2, 8 ])

    it 'should supply a varying parameter to inline-map', ->
      { dynamic } = from.default

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
      { alpha, beta, gamma } = custom = defcase('org.janusjs.test', 'alpha', 'beta', 'gamma')

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
      { dynamic, other } = custom = defcase('org.janusjs.test', 'dynamic', 'other')

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
      { a, b } = custom = defcase('org.janusjs.test', 'a', 'b')

      from.build(custom).should.not.be.a.Function

  describe 'deferred point calling order', ->
    it 'should work with reactLater', ->
      { dynamic } = from.default

      f = from('a').and('b')
        .all.map((a, b) -> a + b)

      iv = new Varying('c')
      v = f.point(match(
        dynamic (x) -> iv.flatMap((y) -> new Varying(x + y))
        otherwise ->
      ))

      result = null
      v.reactLater((x) -> result = x)
      (result is null).should.be.true

      iv.set('d')
      result.should.equal('adbd')

    it 'should work with react', ->
      { dynamic } = from.default

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

