should = require('should')

{ defcase, match, otherwise } = require('../../lib/core/case')

describe 'case', ->
  describe 'set', ->
    describe 'definition', ->
      it 'should return a list of functions', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        success.should.be.a.Function
        fail.should.be.a.Function

      it 'should return a list of functions that return case objects', ->
        { mycase } = defcase('org.janusjs.test', 'mycase')
        mycase().toString().should.equal('mycase: undefined')

      it 'should return a list of functions that return identity strings that contain values', ->
        { outer } = defcase('org.janusjs.test', 'outer')
        outer('inner').value.should.equal('inner')

      it 'should take decorated case names via k/v pairs', ->
        { success, fail } = defcase('org.janusjs.test',
          success:
            custom: 'pair'
          fail:
            can: 'override'
        )
        success().custom.should.equal 'pair'
        fail().can.should.equal 'override'

      it 'should take a mix of decorated and undecorated cases: (str, obj)', ->
        { success, fail } = defcase('org.janusjs.test', 'success', fail: decorated: true )
        success.should.be.a.Function
        fail().decorated.should.be.true

      it 'should take a mix of decorated and undecorated cases: (obj, str)', ->
        { success, fail } = defcase('org.janusjs.test', success: decorated: true, 'fail')
        success().decorated.should.be.true
        fail.should.be.a.Function

      it 'should take a mix of decorated and undecorated cases: (str, obj, str)', ->
        { dunno, success, fail } = defcase('org.janusjs.test', 'dunno', success: decorated: true, 'fail')
        dunno.should.be.a.Function
        success().decorated.should.be.true
        fail.should.be.a.Function

      it 'should take a namespace as its first parameter and remember it', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail' )
        success.namespace.should.equal('org.janusjs.test')

      it 'should take decorations attached to the namespace and apply them', ->
        { success, fail } = defcase( 'org.janusjs.test': { decoration: 42 }, 'success', 'fail' )
        success().decoration.should.equal(42)

      it 'should let case decorations override namespace decorations', ->
        { success, fail } = defcase( 'org.janusjs.test': { decoration: 42 }, 'success', fail: { decoration: 13 } )
        success.namespace.should.equal('org.janusjs.test')
        success().decoration.should.equal(42)
        fail().decoration.should.equal(13)

      it 'should let set decorations override default decorations', ->
        { success, fail } = defcase( 'org.janusjs.test': { toString: -> 'hi' }, 'success', 'fail')
        success().toString().should.equal('hi')

      it 'should read child cases from direct arrays', ->
        { nothing, something, onething, twothings } = defcase('org.janusjs.test', 'nothing', something: [ 'onething', 'twothings' ])
        onething(1).toString().should.equal('onething: 1')
        twothings(2).toString().should.equal('twothings: 2')

      it 'should read child cases from prop definition', ->
        { nothing, something, onething, twothings } = defcase('org.janusjs.test', 'nothing', something: { children: [ 'onething', 'twothings' ] })
        onething(1).toString().should.equal('onething: 1')
        twothings(2).toString().should.equal('twothings: 2')

      it 'should read twice-nested child cases', ->
        cases = defcase('org.janusjs.test', 'nothing', something: [ onething: [ 'redfish', 'bluefish' ], twothings: { children: [ 'pairfish' ] } ] )
        for x, y in [ 'nothing', 'something', 'onething', 'redfish', 'bluefish', 'twothings', 'pairfish' ]
          cases[x](y).toString().should.equal("#{x}: #{y}")

      it 'should decorate child cases appropriately', ->
        { nesteda, nestedb } = defcase('org.janusjs.test', 'topa': [ nesteda: { decoration: 3, children: [ nestedb: { decoration: 89 } ] } ] )
        nesteda().decoration.should.equal(3)
        nestedb().decoration.should.equal(89)

    describe 'instance', ->
      it 'should map values to the same type', ->
        { test } = defcase('org.janusjs.test', 'test')
        x = test('a')
        x.value.should.equal('a')

        y = x.map((v) -> v + 'b')
        y.type.should.equal('test')
        y.value.should.equal('ab')

      it 'should return its inner value if it passes XOrElse, otherwise else', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        success(42).successOrElse(13).should.equal(42)
        fail(4).successOrElse(47).should.equal(47)

      it 'should return its inner value if it passes getX, otherwise self', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        success('awesome').getSuccess().should.equal('awesome')
        fail('awesome').getSuccess().type.should.equal('fail')
        fail('awesome').getSuccess().value.should.equal('awesome')

      it 'should map its inner value on mapT if it matches T', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        result = success('cool').mapSuccess((x) -> x + ' beans')
        result.type.should.equal('success')
        result.value.should.equal('cool beans')

      it 'should map its inner value on mapT only if it matches T', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        result = success('cool').mapFail((x) -> x + ' beans')
        result.type.should.equal('success')
        result.value.should.equal('cool')

      it 'should return a friendly string on toString', ->
        { friendly } = defcase('org.janusjs.test', 'friendly')
        friendly('string').toString().should.equal('friendly: string')

  describe 'match', ->
    describe 'single case', ->
      it 'should run the given function if the provided instance matches the case', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        called = false
        success.match(success(1), (-> called = true))
        called.should.equal(true)

      it 'should provide the inner value if the instance matches the case', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        given = null
        success.match(success(1), ((x) -> given = x))
        given.should.equal(1)

      it 'should not run the given function unless the provided instance matches the case', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        called = false
        success.match(fail(1), (-> called = true))
        called.should.equal(false)

      it 'defaults to returning boolean on the instance matching the case if no function is provided', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        success.match(success(1)).should.equal(true)
        fail.match(success(1)).should.equal(false)

      it 'uses unapply as appropriate', ->
        { success, fail } = defcase('org.janusjs.test': { arity: 2 }, 'success', 'fail')
        results = []
        success.match(success(1, 2), (x, y) -> results.push(x, y))
        results.should.eql([ 1, 2 ])

      it 'matches child cases', ->
        { pending, complete, success, fail } = defcase('org.janusjs.test', 'pending', 'complete': [ 'success', 'fail' ])

        complete.match(success()).should.equal(true)
        complete.match(fail()).should.equal(true)
        complete.match(complete()).should.equal(true)

    describe 'initialization', ->
      it 'should return a function', ->
        match().should.be.a.Function

      it 'should be happy if i have all declared types present', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        match(
          success, 1
          fail, 2
        ).should.be.a.Function

      it 'should be unhappy if i haven\'t all declared types present', ->
        { success, fail, dunno } = defcase('org.janusjs.test', 'success', 'fail', 'dunno')
        (->
          match(
            success, 1
            fail, 2
          )
        ).should.throw()

      it 'should be happy if i havent\'t all declared types present, but i have otherwise', ->
        { success, fail, dunno } = defcase('org.janusjs.test', 'success', 'fail', 'dunno')
        match(
          success, 1
          otherwise, 2
        ).should.be.a.Function

      it 'should allow for direct function call syntax', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        match(
          success -> 1
          fail -> 2
        ).should.be.a.Function

      it 'should allow for a mix of function call and comma syntaxes', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        match(
          success, 1
          fail -> 2
        ).should.be.a.Function

    describe 'pattern matching', ->
      it 'should return a correct direct match: first case', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        match(
          success, 1
          fail, 2
        )(success()).should.equal(1)

      it 'should return a correct direct match: second case', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        match(
          success, 1
          fail, 2
        )(fail()).should.equal(2)

      it 'should use otherwise if nothing matched', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        m = match(
          success, 1
          otherwise, 3
        )

        m(fail()).should.equal(3)
        m().should.equal(3)

      it 'should return a correct direct function call match: first case', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        match(
          success -> 1
          fail -> 2
        )(success()).should.equal(1)

      it 'should return a correct direct function call match: second case', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        match(
          success, 1
          fail -> 2
        )(fail()).should.equal(2)

      it 'should not match like-named cases from other sets', ->
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        success2 = defcase('org.janusjs.test2', 'success').success

        match(
          success -> 1
          otherwise -> 2
        )(success2()).should.equal(2)

    describe 'hierarchy', ->
      it 'should consider child types seen if it has seen the parent', ->
        { pending, complete, success, fail } = defcase('org.janusjs.test', 'pending', 'complete': [ 'success', 'fail' ])

        (->
          match(
            pending, 1
            complete, 2
          )
        ).should.not.throw()

      it 'should match against the parent case if found', ->
        { pending, complete, success, fail } = defcase('org.janusjs.test', 'pending', 'complete': [ 'success', 'fail' ])
        m = match(
          pending -> 12
          complete -> 24
        )
        m(success()).should.equal(24)
        m(fail()).should.equal(24)
        m(complete()).should.equal(24)

    describe 'unapplying', ->
      it 'should call my result handler with the inner value', ->
        matched = false

        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        m = match(
          success, (x) -> matched = x
          otherwise, null
        )

        m(success(true)).should.be.true
        matched.should.be.true

      it 'should additionally pass along additional arguments if provided', ->
        a = b = c = null
        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        m = match(
          success (x, y, z) -> a = x; b = y; c = z
          otherwise -> null
        )

        m(success(1), 2, 3)
        a.should.equal(1)
        b.should.equal(2)
        c.should.equal(3)

      it 'should allow for custom unapply', ->
        matched = false

        { success, fail } = defcase('org.janusjs.test',
          success: unapply: (f) -> f( result: this.value )
          'fail'
        )
        m = match(
          success, (x) -> matched = x.result
          otherwise, null
        )

        m(success(true)).should.be.true
        matched.should.be.true

      it 'should call my result handler with the inner value given function call syntax', ->
        matched = false

        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        m = match(
          success (x) -> matched = x
          otherwise, null
        )

        m(success(true)).should.be.true
        matched.should.be.true

      it 'should allow use of otherwise in function call style', ->
        result = null

        { success, fail } = defcase('org.janusjs.test', 'success', 'fail')
        m = match(
          success -> 'success'
          otherwise (x) -> result = x
        )

        m('otherwise').should.equal('otherwise')
        result.should.equal('otherwise')

      it 'should leave cases of other sets intact when otherwised', ->
        result = null

        { success } = defcase('org.janusjs.test', 'success')
        { fail } = defcase('org.janusjs.test2', 'fail')

        m = match(
          success -> 'success'
          otherwise (x) -> result = x
        )

        m(fail('test')).type.should.equal('fail')

      it 'should allow 2-arity cases', ->
        results = []
        { success, fail } = defcase('org.janusjs.test', success: { arity: 2 }, 'fail')
        m = match(
          success (x, y) -> results.push(x, y)
          fail (x, y) -> results.push(x, y)
        )

        m(success(7, 11))
        m(fail(13, 17))
        results.should.eql([ 7, 11, 13, undefined ])

      it 'should allow 3-arity cases', ->
        results = []
        { success, fail } = defcase('org.janusjs.test', success: { arity: 3 }, 'fail')
        m = match(
          success (x, y, z) -> results.push(x, y, z)
          fail (x, y, z) -> results.push(x, y, z)
        )

        m(success(7, 11, 13))
        m(fail(17, 19, 23))
        results.should.eql([ 7, 11, 13, 17, undefined, undefined ])

      it 'should allow additional params for multi-arity cases', ->
        results = []
        { success, fail } = defcase('org.janusjs.test', success: { arity: 3 }, fail: { arity: 2 })
        m = match(
          success (x, y, z, w) -> results.push(x, y, z, w)
          fail (x, y, z, w) -> results.push(x, y, z, w)
        )

        m(success(7, 11, 13), 17)
        m(fail(19, 23, 27), 31)
        results.should.eql([ 7, 11, 13, 17, 19, 23, 31, undefined ])

