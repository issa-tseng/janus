should = require('should')

from = require('../../lib/core/from')
cases = require('../../lib/core/types').from
{ Case, match, otherwise } = require('../../lib/core/case')
Varying = require('../../lib/core/varying').Varying

id = (x) -> x

describe 'from', ->
  should.Assertion.add('val', (->
    this.params = { operator: 'to be a val' }
    this.obj.should.be.an.Object()

    this.obj.map.should.be.a.Function()
    this.obj.flatMap.should.be.a.Function()
    this.obj.and.should.be.a.Function()
    this.obj.all.should.be.an.Object()
  ), true)

  describe 'initial val', ->
    it 'should return a val-looking thing', ->
      should(from('a')).be.a.val()

    it 'should contain functions that return val-looking things', ->
      should(from.get('b')).be.a.val()
      should(from.attribute('b')).be.a.val()
      should(from.varying('b')).be.a.val()

    it 'should not contain function called dynamic', ->
      (from.dynamic?).should.equal(false)

  describe 'val', ->
    it 'should return a val-looking thing on map', ->
      should(from('a').map(->)).be.a.val()

    it 'should return a val-looking thing on flatMap', ->
      should(from('a').flatMap(->)).be.a.val()

    it 'should return a conjunction-looking thing on and', ->
      conjunction = from('a').and
      conjunction.should.be.a.Function()
      conjunction.get.should.be.a.Function()
      conjunction.attribute.should.be.a.Function()
      conjunction.varying.should.be.a.Function()

    it 'should return a terminus-looking thing on all', ->
      terminus = from('a').all
      terminus.should.be.an.Object()

      terminus.point.should.be.a.Function()
      terminus.flatMap.should.be.a.Function()
      terminus.map.should.be.a.Function()
      terminus.all.should.equal(terminus)

  describe 'point', ->
    it 'should return a true varying', ->
      from('a').all.point(->).isVarying.should.equal(true)

    it 'should execute a pointing function with the case', ->
      args = []

      from('a')
        .and.get('b')
        .and.attribute('d')
        .and.varying('e')
        .all.point((x) -> args.push(x); x)

      args[0].should.be.an.instanceof(cases.dynamic.type)
      args[0].get().should.equal('a')

      args[1].should.be.an.instanceof(cases.get.type)
      args[1].get().should.equal('b')

      args[2].should.be.an.instanceof(cases.attribute.type)
      args[2].get().should.equal('d')

      args[3].should.be.an.instanceof(cases.varying.type)
      args[3].get().should.equal('e')

    it 'should only point for things that have not resolved to varying', ->
      { dynamic, get, definition, varying } = cases

      count = 0
      incr = (f) -> (args...) -> count += 1; f(args...)

      f1 = from('a')
        .and.get('b')
        .all.point(match(
          dynamic incr (xs...) -> new Varying()
          otherwise incr id
        ))

      count.should.equal(2)

      f2 = f1.point(match(
        get incr (xs...) -> new Varying()
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
        .and.get('b')
        .all.map (xs...) ->
          called = true

          xs.length.should.equal(2)

          xs[0].should.be.a.Function()
          xs[1].should.be.a.Function()

      called.should.equal(false)

      v.point().react(->)
      called.should.equal(true)

    it 'should be called with resolved applicants', ->
      { dynamic, get, definition, varying } = cases
      called = false

      v = from('a')
        .and.get('b')
        .all.point(match(
          dynamic (x) -> new Varying("dynamic: #{x}")
          get (x) -> new Varying("get: #{x}")
          otherwise -> null
        )).map((xs...) ->
          called = true

          xs.length.should.equal(2)

          xs[0].should.equal('dynamic: a')
          xs[1].should.equal('get: b')
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
      { dynamic, get, definition, varying } = cases
      called = false

      v = from('a')
        .and.get('b')
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
      { dynamic, get, definition, varying } = cases
      result = null

      v = from('a').and('b').and('c')
        .all.point(match(
          dynamic (x) -> new Varying(x)
          otherwise id
        )).react((xs...) -> result = xs)

      result.should.eql([ 'a', 'b', 'c' ])

    it 'should return a single applicant as the argument absent an allmapper', ->
      { dynamic, get, definition, varying } = cases
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

  describe 'inline get', ->
    it 'should apply as a flatMap after point resolution', ->
      { dynamic } = cases

      called = null
      result = null
      iv = new Varying(2)
      from('a').get('myattr')
        .all.point(match(
          dynamic -> new Varying({ get: (x) -> called = x; iv })
          otherwise ->
        ))
        .map(id).react((x) -> result = x)

      called.should.equal('myattr')
      result.should.equal(2)

    it 'should return null (not undef) if the watch fails', ->
      { dynamic } = cases

      result = null
      iv = new Varying(2)
      from('a').get('myattr')
        .all.point(match(
          dynamic -> new Varying()
        ))
        .map(id).react((x) -> result = x)

      (result is null).should.equal(true)

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

    it 'should return null (not undef) if the attribute cannot be found', ->
      { dynamic } = cases

      result = null
      iv = new Varying(2)
      from('a').attribute('myattr')
        .all.point(match(
          dynamic -> new Varying()
        ))
        .map(id).react((x) -> result = x)

      (result is null).should.equal(true)

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
      { alpha, beta, gamma } = custom = Case.build('alpha', 'beta', 'gamma')

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
      { dynamic, other } = custom = Case.build('dynamic', 'other')

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
      { a, b } = custom = Case.build('a', 'b')

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

