should = require('should')

{ extendNew } = require('../../lib/util/util')
{ find, template } = require('../../lib/view/template')

describe 'templater', ->
  describe 'find', ->
    it 'returns an object with mutator functions first-order', ->
      find('a').attr.should.be.a.Function
      find('a').render.should.be.a.Function

    it 'returns a function1 when a mutator is called', ->
      result = find('a').css()
      result.should.be.a.Function
      result.length.should.equal(1)

    it 'passes the selector along to the dom obj when called second-order', ->
      selector = null
      dom = { find: (x) -> selector = x }
      find('a').text()(dom)
      selector.should.equal('a')

    describe 'build', ->
      it 'mixes in our mutators', ->
        mutators = { test: (->), zebra: (->) }
        myfind = find.build(mutators)
        myfind('a').test.should.be.a.Function
        myfind('a').zebra.should.be.a.Function

      it 'ignores the default mutators', ->
        mutators = { test: (->), zebra: (->) }
        myfind = find.build(mutators)
        should(myfind('a').attr).equal(undefined)
        should(myfind('a').render).equal(undefined)

    describe 'mutator first-order calling', ->
      it 'should pass the correct arguments', ->
        a = null
        b = null
        mutators = { test: (x, y) -> a = x; b = y }
        myfind = find.build(mutators)

        myfind('a').test(1, 2)
        a.should.equal(1)
        b.should.equal(2)

    describe 'mutator chaining', ->
      it 'retains object permeance in chaining', ->
        allArgs = null
        mymutator = (args = {}) ->
          result = (->)
          result.chain = (moreArgs) ->
            allArgs = extendNew(args, moreArgs)
            mymutator(allArgs)
          result

        myfind = find.build({ test: mymutator })
        myfind('a').test({ a: 1 }).chain({ b: 2 }).chain({ c: 3 })
        allArgs.should.eql({ a: 1, b: 2, c: 3 })

      it 'always returns a function1 in chaining', ->
        mymutator = (args = {}) ->
          result = (->)
          result.chain = (moreArgs) -> mymutator(extendNew(args, moreArgs))
          result

        myfind = find.build({ test: mymutator })
        result = myfind('a').test({ a: 1 }).chain({ b: 2 }).chain({ c: 3 })
        result.should.be.a.Function
        result.length.should.equal(1)

    describe 'finalizing', ->
      it 'should call the final order on mutator when pointed', ->
        called = false
        mymutator = () -> () -> called = true
        myfind = find.build({ test: mymutator })

        dom = { find: (->) }
        found = myfind('a').test()(dom)
        called.should.equal(false)
        found()
        called.should.equal(true)

      it 'should call the final order on mutator with the correct context arguments', ->
        givenDom = givenPoint = null
        dom = { find: -> 1 }
        point = -> 2
        mymutator = () -> (dom, point) -> givenDom = dom; givenPoint = point
        myfind = find.build({ test: mymutator })

        myfind('a').test()(dom)(point)
        givenDom.should.equal(1)
        givenPoint.should.be.a.Function
        givenPoint().should.equal(2)

      it 'should call the final order on mutator with the correct first-order arguments', ->
        x = y = null
        mymutator = (a, b) -> (dom, point) -> x = a; y = b
        myfind = find.build({ test: mymutator })

        myfind('a').test(3, 4)({ find: -> })(->)
        x.should.equal(3)
        y.should.equal(4)

  describe 'template', ->
    m = (cb) -> (dom) ->
      cb(dom)
      (point) -> cb(point)

    it 'returns a function', ->
      template().should.be.a.Function
      template(->).should.be.a.Function

    it 'calls all directly passed mutators (first-order)', ->
      all = []
      cb = (val) -> m((x) -> all.push(val, x))

      template(cb(1), cb(2), cb(3))(9)
      all.should.eql([ 1, 9, 2, 9, 3, 9 ])

    it 'calls all nested mutators (first-order)', ->
      all = []
      cb = (val) -> m((x) -> all.push(val, x))

      template(cb(1), template(cb(2), cb(3)))(9)
      all.should.eql([ 1, 9, 2, 9, 3, 9 ])

    it 'calls all deeply nested mutators (first-order)', ->
      all = []
      cb = (val) -> m((x) -> all.push(val, x))

      template(cb(1), template(cb(2), template(cb(3), cb(4))))(9)
      all.should.eql([ 1, 9, 2, 9, 3, 9, 4, 9 ])

    it 'calls all mutators (second-order)', ->
      all = []
      cb = (val) -> m((x) -> all.push(val, x))

      template(cb(1), template(cb(2), template(cb(3), cb(4))))(9)(99)
      all.should.eql([ 1, 9, 2, 9, 3, 9, 4, 9, 1, 99, 2, 99, 3, 99, 4, 99 ])

    it 'returns all final objs flatly (second-order call)', ->
      cb = (val) -> m(-> val)
      template(cb(1), template(cb(2), template(cb(3), cb(4))))()().should.eql([ 1, 2, 3, 4 ])

