should = require('should')

{ extendNew } = require('../../lib/util/util')
{ Varying } = require('../../lib/core/varying')
{ find, template } = require('../../lib/view/template')
$ = require('jquery')(require('domino').createWindow())

describe 'templater', ->
  describe 'find', ->
    it 'returns an object with mutator functions first-order', ->
      find('a').attr.should.be.a.Function
      find('a').render.should.be.a.Function

    it 'returns a function1 when a mutator is called', ->
      result = find('a').css()
      result.should.be.a.Function
      result.length.should.equal(1)

    describe 'selection', ->
      it 'selects appropriately the root node', ->
        nodes = null
        testfind = find.build({ test: (_) -> (x) -> nodes = x })
        mutator = testfind('.root').test()

        fragment = $('<div class="root"><div/></div>')
        mutator(fragment)(fragment)
        nodes.length.should.equal(1)
        nodes[0].should.equal(fragment[0])

      it 'selects appropriately from amongst sibling branches', ->
        nodes = null
        testfind = find.build({ test: (_) -> (x) -> nodes = x })
        mutator = testfind('.target').test()

        fragment = $('<div><div/><div><div class="target"/></div></div>')
        mutator(fragment)(fragment)
        nodes.length.should.equal(1)
        nodes[0].should.equal(fragment.find('.target').get(0))

      it 'selects appropriately multiple nodes', ->
        nodes = null
        testfind = find.build({ test: (_) -> (x) -> nodes = x })
        mutator = testfind('span').test()

        fragment = $('<div class="root"><span><span/></span></div>')
        mutator(fragment)(fragment)
        nodes.length.should.equal(2)
        nodes.get(0).should.equal(fragment.children().get(0))
        nodes.get(1).should.equal(fragment.children().children().get(0))

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

    # tests chaining within a mutator's own return value (ie .render().options()).
    describe 'mutator chaining', ->
      it 'retains object permanence in chaining', ->
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

    # tests chaining across different mutators.
    describe 'multi-mutator chaining', ->
      it 'executes all chained mutators', ->
        results = []
        makeMutator = (id) -> () -> () -> results.push(id)
        testfind = find.build({ a: makeMutator('a'), b: makeMutator('b'), c: makeMutator('c') })

        fragment = $('<div/>')
        testfind('div').b().a().c().b()(fragment)(fragment)
        results.should.eql([ 'b', 'a', 'c', 'b' ])

      it 'provides the appropriate arguments to all mutators', ->
        results = []
        makeMutator = (id) -> (x, y) -> (dom, point) -> results.push([ id, x, y, dom.get(0), point ])
        testfind = find.build({ a: makeMutator('a'), b: makeMutator('b') })

        fragment = $('<div/>')
        point = (->)
        testfind('div').b(1, 2).a(3, 4).b(5, 6)(fragment)(fragment, point)

        dom = fragment.get(0)
        results.should.eql([
          [ 'b', 1, 2, dom, point ],
          [ 'a', 3, 4, dom, point ],
          [ 'b', 5, 6, dom, point ]
        ])

      it 'selects the appropriate node for all mutators', ->
        results = []
        makeMutator = (id) -> () -> (dom) -> results.push(dom.get(0))
        testfind = find.build({ a: makeMutator('a'), b: makeMutator('b') })

        fragment = $('<div><span/><div><p class="target"/></div></div>')
        testfind('.target').b().a()(fragment)(fragment)

        dom = fragment.find('.target').get(0)
        results.should.eql([ dom, dom ])

      it 'returns a flattened list of Observations', ->
        result = []
        v = new Varying(2)
        makeMutator = (id) -> (x) -> () -> v.map((y) -> x + y).react((z) -> result.push(z))
        testfind = find.build({ a: makeMutator('a'), b: makeMutator('b') })

        fragment = $('<div/>')
        observations = testfind('div').a(4).b(8)(fragment)(fragment)
        observations.length.should.equal(2)
        observations[0].parent.should.be.an.instanceof(Varying)
        observations[1].parent.should.be.an.instanceof(Varying)
        result.should.eql([ 6, 10 ])

        observations[1].stop()
        v.set(0)
        result.should.eql([ 6, 10, 4 ])

      it 'intermixes mutator/multi-mutator chaining', ->
        chainingMutator = (args = {}) ->
          result = -> Varying.ly(args).react(->)
          result.chain = (moreArgs) -> chainingMutator(extendNew(args, moreArgs))
          result
        makeMutator = (id) -> (x) -> () -> Varying.ly(x).react(->)

        myfind = find.build({ chaining: chainingMutator, a: makeMutator('a'), b: makeMutator('b') })
        fragment = $('<div/>')
        observations = myfind('div')
          .a(3)
          .chaining({ x: 5 }).chain({ y: 7 })
          .b(9)(fragment)(fragment)
        observations.length.should.equal(3)
        observations[0].parent.get().should.equal(3)
        observations[1].parent.get().should.eql({ x: 5, y: 7 })
        observations[2].parent.get().should.equal(9)

      it 'does not clobber mutator chaining', ->
        chainingMutator = (args = {}) ->
          result = -> Varying.ly(args).react(->)
          result.chain = (moreArgs) -> chainingMutator(extendNew(args, moreArgs))
          result
        makeMutator = (id) -> (x) -> () -> Varying.ly(x).react(->)

        myfind = find.build({ chaining: chainingMutator, x: makeMutator('x'), chain: makeMutator('chain') })
        fragment = $('<div/>')
        observations = myfind('div')
          .chain(3)
          .chaining({ x: 5 }).chain({ y: 7 })
          .x(9)(fragment)(fragment)
        observations.length.should.equal(3)
        observations[0].parent.get().should.equal(3)
        observations[1].parent.get().should.eql({ x: 5, y: 7 })
        observations[2].parent.get().should.equal(9)

    describe 'finalizing', ->
      it 'should call the final order on mutator when pointed', ->
        called = false
        mymutator = () -> () -> called = true
        myfind = find.build({ test: mymutator })

        dom = $('<div/>')
        found = myfind('a').test()(dom)
        called.should.equal(false)
        found(dom)
        called.should.equal(true)

      it 'should call the final order on mutator with the correct context arguments', ->
        givenDom = givenPoint = null
        dom = $('<a/>')
        point = -> 2
        mymutator = () -> (dom, point) -> givenDom = dom; givenPoint = point
        myfind = find.build({ test: mymutator })

        myfind('a').test()(dom)(dom, point)
        givenDom[0].should.equal(dom[0])
        givenPoint.should.be.a.Function
        givenPoint().should.equal(2)

      it 'should call the final order on mutator with the correct first-order arguments', ->
        x = y = null
        mymutator = (a, b) -> (dom, point) -> x = a; y = b
        myfind = find.build({ test: mymutator })

        dom = $('<div/>')
        myfind('a').test(3, 4)(dom)(dom)
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

