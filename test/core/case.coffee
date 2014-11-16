should = require('should')

{ caseSet, match, otherwise } = require('../../lib/core/case')

describe 'case', ->
  describe 'set', ->
    describe 'definition', ->
      it 'should return a list of functions', ->
        { success, fail } = caseSet('success', 'fail')
        success.should.be.a.Function
        fail.should.be.a.Function

      it 'should return a list of functions that return identity strings', ->
        { mycase } = caseSet('mycase')
        mycase().should.equal('mycase')

      it 'should return a list of functions that return identity strings that contain values', ->
        { outer } = caseSet('outer')
        outer('inner').value.should.equal('inner')

      it 'should take decorated case names via k/v pairs', ->
        { success, fail } = caseSet(
          success:
            custom: 'pair'
          fail:
            can: 'override'
        )
        success().custom.should.equal 'pair'
        fail().can.should.equal 'override'

      it 'should take a mix of decorated and undecorated cases: (str, obj)', ->
        { success, fail } = caseSet('success', fail: decorated: true )
        success.should.be.a.Function
        fail().decorated.should.be.true

      it 'should take a mix of decorated and undecorated cases: (obj, str)', ->
        { success, fail } = caseSet( success: decorated: true, 'fail')
        success().decorated.should.be.true
        fail.should.be.a.Function

      it 'should take a mix of decorated and undecorated cases: (str, obj, str)', ->
        { dunno, success, fail } = caseSet('dunno', success: decorated: true, 'fail')
        dunno.should.be.a.Function
        success().decorated.should.be.true
        fail.should.be.a.Function

    describe 'instance', ->
      it 'should map values to the same type', ->
        { test } = caseSet('test')
        x = test('a')
        x.value.should.equal('a')

        y = x.map((v) -> v + 'b')
        y.should.equal('test')
        y.value.should.equal('ab')

      it 'should return its inner value if it passes XOrElse, otherwise else', ->
        { success, fail } = caseSet('success', 'fail')
        success(42).successOrElse(13).should.equal(42)
        fail(4).successOrElse(47).should.equal(47)

      it 'should return its inner value if it passes flatX, otherwise self', ->
        { success, fail } = caseSet('success', 'fail')
        success('awesome').flatSuccess().should.equal('awesome')
        fail('awesome').flatSuccess().should.equal('fail')
        fail('awesome').flatSuccess().value.should.equal('awesome')

      it 'should return a friendly string on toString', ->
        { friendly } = caseSet('friendly')
        friendly('string').toString().should.equal('friendly: string')

  describe 'match', ->
    describe 'initialization', ->
      it 'should return a function', ->
        match().should.be.a.Function

      it 'should be happy if i have all declared types present', ->
        { success, fail } = caseSet('success', 'fail')
        match(
          success, 1
          fail, 2
        ).should.be.a.Function

      it 'should be unhappy if i haven\'t all declared types present', ->
        { success, fail, dunno } = caseSet('success', 'fail', 'dunno')
        (->
          match(
            success, 1
            fail, 2
          )
        ).should.throw()

      it 'should be happy if i havent\'t all declared types present, but i have otherwise', ->
        { success, fail, dunno } = caseSet('success', 'fail', 'dunno')
        match(
          success, 1
          otherwise, 2
        ).should.be.a.Function

      it 'should allow for direct function call syntax', ->
        { success, fail } = caseSet('success', 'fail')
        match(
          success -> 1
          fail -> 2
        ).should.be.a.Function

      it 'should allow for a mix of function call and comma syntaxes', ->
        { success, fail } = caseSet('success', 'fail')
        match(
          success, 1
          fail -> 2
        ).should.be.a.Function

    describe 'pattern matching', ->
      it 'should return a correct direct match: first case', ->
        { success, fail } = caseSet('success', 'fail')
        match(
          success, 1
          fail, 2
        )(success()).should.equal(1)

      it 'should return a correct direct match: second case', ->
        { success, fail } = caseSet('success', 'fail')
        match(
          success, 1
          fail, 2
        )(fail()).should.equal(2)

      it 'should use otherwise if nothing matched', ->
        { success, fail } = caseSet('success', 'fail')
        m = match(
          success, 1
          otherwise, 3
        )

        m(fail()).should.equal(3)
        m().should.equal(3)

      it 'should return a correct direct function call match: first case', ->
        { success, fail } = caseSet('success', 'fail')
        match(
          success -> 1
          fail -> 2
        )(success()).should.equal(1)

      it 'should return a correct direct function call match: second case', ->
        { success, fail } = caseSet('success', 'fail')
        match(
          success, 1
          fail -> 2
        )(fail()).should.equal(2)

    describe 'unapplying', ->
      it 'should call my result handler with the inner value', ->
        matched = false

        { success, fail } = caseSet('success', 'fail')
        m = match(
          success, (x) -> matched = x
          otherwise, null
        )

        m(success(true)).should.be.true
        matched.should.be.true

      it 'should allow for custom unapply', ->
        matched = false

        { success, fail } = caseSet(
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

        { success, fail } = caseSet('success', 'fail')
        m = match(
          success (x) -> matched = x
          otherwise, null
        )

        m(success(true)).should.be.true
        matched.should.be.true

