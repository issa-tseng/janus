should = require('should')

{ extendNew } = require('../../lib/util/util')
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

