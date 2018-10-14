should = require('should')

{ Case, match, otherwise } = require('../../lib/core/case')

unapply1 = (kase) -> (x) -> new kase(x, (f) -> f(x))
unapply2 = (kase) -> (x, y) -> new kase(x, (f) -> f(x, y))
unapply3 = (kase) -> (x, y, z) -> new kase(x, (f) -> f(x, y, z))

describe 'case', ->
  describe 'set', ->
    describe 'definition', ->
      it 'should return a list of functions', ->
        { success, fail } = Case.build('success', 'fail')
        success.should.be.a.Function()
        fail.should.be.a.Function()

      it 'should return a list of functions that return case objects', ->
        { mycase } = Case.build('mycase')
        mycase().toString().should.equal('case[mycase]: undefined')

      it 'should take a mix of decorated and undecorated cases: (str, obj)', ->
        { success, fail } = Case.build('success', fail: unapply2)
        success.should.be.a.Function()
        fail.should.be.a.Function()
        fail.length.should.equal(2)

      it 'should take a mix of decorated and undecorated cases: (obj, str)', ->
        { success, fail } = Case.build(success: unapply2, 'fail')
        success.should.be.a.Function()
        success.length.should.equal(2)
        fail.should.be.a.Function()

      it 'should take a mix of decorated and undecorated cases: (str, obj, str)', ->
        { dunno, success, fail } = Case.build('dunno', success: unapply2, 'fail')
        dunno.should.be.a.Function()
        success.should.be.a.Function()
        success.length.should.equal(2)
        fail.should.be.a.Function()

      it 'should take arity global option and use it throughout', ->
        { success, fail } = Case.withOptions({ arity: 2 }).build('success', 'fail' )
        success.length.should.equal(2)
        fail.length.should.equal(2)

      it 'should let case unapply override global arity option', ->
        { success, fail } = Case.withOptions({ arity: 3 }).build('success', fail: unapply2)
        success.length.should.equal(3)
        fail.length.should.equal(2)

      it 'should read child cases from direct arrays', ->
        { nothing, something, onething, twothings } = Case.build('nothing', something: [ 'onething', 'twothings' ])
        onething(1).toString().should.equal('case[onething]: 1')
        twothings(2).toString().should.equal('case[twothings]: 2')

      it 'should read child cases from prop definition', ->
        { nothing, something, onething, twothings } = Case.build('nothing', something: { 'onething': unapply1, 'twothings': unapply1 })
        onething(1).toString().should.equal('case[onething]: 1')
        twothings(2).toString().should.equal('case[twothings]: 2')

      it 'should read twice-nested child cases', ->
        cases = Case.build('nothing', something: [ onething: [ 'redfish', 'bluefish' ], twothings: { pairfish: unapply1 } ] )
        for x, y in [ 'nothing', 'redfish', 'bluefish', 'pairfish' ]
          cases[x](y).toString().should.equal("case[#{x}]: #{y}")

      it 'should set unapply for child cases appropriately', ->
        { nesteda, nestedb } = Case.build(top: [ nesteda: [ nestedb: unapply3 ] ])
        nestedb.length.should.equal(3)

    describe 'instance', ->
      it 'should get the inner value no matter what on .get()', ->
        { test } = Case.build('test')
        test('a').get().should.equal('a')

      it 'should return its inner value if it passes TOrElse, otherwise else', ->
        { success, fail } = Case.build('success', 'fail')
        success(42).successOrElse(13).should.equal(42)
        fail(4).successOrElse(47).should.equal(47)

      it 'should return its inner value if it passes getT, otherwise self', ->
        { success, fail } = Case.build('success', 'fail')
        success('awesome').getSuccess().should.equal('awesome')
        fail('awesome').getSuccess().should.be.an.instanceof(fail.type)
        fail('awesome').getSuccess().get().should.equal('awesome')

      it 'should map values to the same type', ->
        { test } = Case.build('test')
        x = test('a')
        x.get().should.equal('a')

        y = x.map((v) -> v + 'b')
        y.should.be.an.instanceof(test.type)
        y.get().should.equal('ab')

      it 'should map its inner value on mapT if it matches T', ->
        { success, fail } = Case.build('success', 'fail')
        result = success('cool').mapSuccess((x) -> x + ' beans')
        result.should.be.an.instanceof(success.type)
        result.get().should.equal('cool beans')

      it 'should map its inner value on mapT only if it matches T', ->
        { success, fail } = Case.build('success', 'fail')
        result = success('cool').mapFail((x) -> x + ' beans')
        result.should.be.an.instanceof(success.type)
        result.get().should.equal('cool')

      it 'should return a friendly string on toString', ->
        { friendly } = Case.build('friendly')
        friendly('string').toString().should.equal('case[friendly]: string')

  describe 'match', ->
    describe 'single case', ->
      it 'should run the given function if the provided instance matches the case', ->
        { success, fail } = Case.build('success', 'fail')
        called = false
        success.match(success(1), (-> called = true))
        called.should.equal(true)

      it 'should provide the inner value if the instance matches the case', ->
        { success, fail } = Case.build('success', 'fail')
        given = null
        success.match(success(1), ((x) -> given = x))
        given.should.equal(1)

      it 'should not run the given function unless the provided instance matches the case', ->
        { success, fail } = Case.build('success', 'fail')
        called = false
        success.match(fail(1), (-> called = true))
        called.should.equal(false)

      it 'defaults to returning boolean on the instance matching the case if no function is provided', ->
        { success, fail } = Case.build('success', 'fail')
        success.match(success(1)).should.equal(true)
        fail.match(success(1)).should.equal(false)

      it 'uses unapply as appropriate', ->
        { success, fail } = Case.withOptions({ arity: 2 }).build('success', 'fail')
        results = []
        success.match(success(1, 2), (x, y) -> results.push(x, y))
        results.should.eql([ 1, 2 ])

      it 'matches child cases', ->
        { pending, complete, success, fail } = Case.build('pending', 'complete': [ 'success', 'fail' ])

        complete.match(success()).should.equal(true)
        complete.match(fail()).should.equal(true)
        complete.match(complete()).should.equal(true)

    describe 'full matcher', ->
      it 'should return a correct direct match: first case', ->
        { success, fail } = Case.build('success', 'fail')
        match(
          success -> 1
          fail -> 2
        )(success()).should.equal(1)

      it 'should return a correct direct match: second case', ->
        { success, fail } = Case.build('success', 'fail')
        match(
          success -> 1
          fail -> 2
        )(fail()).should.equal(2)

      it 'should use otherwise if nothing matched', ->
        { success, fail } = Case.build('success', 'fail')
        m = match(
          success -> 1
          otherwise -> 3
        )

        m(fail()).should.equal(3)
        m().should.equal(3)

      it 'should not match like-named cases from other sets', ->
        { success, fail } = Case.build('success', 'fail')
        success2 = Case.build('success').success

        match(
          success -> 1
          otherwise -> 2
        )(success2()).should.equal(2)

    describe 'hierarchy', ->
      it 'should consider child types seen if it has seen the parent', ->
        { pending, complete, success, fail } = Case.build('pending', 'complete': [ 'success', 'fail' ])

        (->
          match(
            pending -> 1
            complete -> 2
          )
        ).should.not.throw()

      it 'should match against the parent case if found', ->
        { pending, complete, success, fail } = Case.build('pending', 'complete': [ 'success', 'fail' ])
        m = match(
          pending -> 12
          complete -> 24
        )
        m(success()).should.equal(24)
        m(fail()).should.equal(24)

      it 'should never match abstract classes', ->
        { pending, complete, success, fail } = Case.build('pending', 'complete': [ 'success', 'fail' ])
        m = match(
          pending -> 12
          complete -> 24
        )
        should.not.exist(m(complete()))

      it 'should not decorate methods for abstract superclasses', ->
        { pending, complete, success, fail } = Case.build('pending', 'complete': [ 'success', 'fail' ])
        should.not.exist(pending().completeOrElse)
        should.not.exist(pending().getComplete)
        should.not.exist(pending().mapComplete)

      it 'should not fulfill methods on abstract superclasses', ->
        { pending, complete, success, fail } = Case.build('pending', 'complete': [ 'success', 'fail' ])
        complete(42).getSuccess().should.be.an.instanceof(complete.type)
        complete(42).successOrElse(0).should.equal(0)
        complete(42).mapSuccess().should.be.an.instanceof(complete.type)

    describe 'unapplying', ->
      it 'should call the result handler with the inner value', ->
        matched = false

        { success, fail } = Case.build('success', 'fail')
        m = match(
          success (x) -> matched = x
          otherwise -> null
        )

        m(success(true)).should.equal(true)
        matched.should.equal(true)

      it 'should work correctly for the default arity option', ->
        a = b = c = null
        { success, fail } = Case.withOptions({ arity: 3 }).build('success', 'fail')
        m = match(
          success (x, y, z) -> a = x; b = y; c = z
          otherwise -> null
        )

        m(success(1, 2, 3))
        a.should.equal(1)
        b.should.equal(2)
        c.should.equal(3)

      it 'should allow for custom unapply', ->
        matched = false

        { success, fail } = Case.build(success: ((kase) -> (x) -> new kase(x, (f) -> f( result: x ))), 'fail')
        m = match(
          success (x) -> matched = x.result
          otherwise -> null
        )

        m(success(true)).should.equal(true)
        matched.should.equal(true)

      it 'should return the whole case for otherwise unapply', ->
        result = null

        { success, fail } = Case.build('success', 'fail')
        m = match(
          success -> 'success'
          otherwise (x) -> result = x; 42
        )

        m(fail('fail')).should.equal(42)
        result.should.be.an.instanceof(fail.type)
        result.get().should.equal('fail')

