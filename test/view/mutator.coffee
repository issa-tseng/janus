should = require('should')

from = require('../../lib/core/from')
{ match, otherwise } = require('../../lib/core/case')
cases = from.default
{ Varying } = require('../../lib/core/varying')
{ Mutator, mutators, _internal: { Mutator1 } } = require('../../lib/view/mutator')


passthrough = match(
  cases.varying (x) -> Varying.ly(x)
  otherwise ->
)

describe 'Mutator', ->
  describe 'base class', ->
    it 'should construct', ->
      (new Mutator(new Varying())).should.be.an.instanceof(Mutator)

    it 'should bind upon calling bind()', ->
      didExec = false
      class TestMutator extends Mutator
        @exec: -> -> didExec = true

      (new TestMutator(from.varying(new Varying()))).bind({})
      didExec.should.be.true

    it 'should provide no value when bound without a point', ->
      calledValue = null
      class TestMutator extends Mutator
        @exec: (x) -> -> calledValue = x

      m = new TestMutator(from.varying(new Varying(4)))
      m.bind({})
      (calledValue?).should.equal(false)

    it 'should provide the current value when calling exec()', ->
      calledValue = null
      class TestMutator extends Mutator
        @exec: (x) -> -> calledValue = x

      m = new TestMutator(from.varying(new Varying(8)))
      m.bind({})
      m.point(match(
        cases.varying (x) -> Varying.ly(x)
        otherwise ->
      ))
      calledValue.should.equal(8)

    it 'should provide the binding when calling exec()', ->
      calledValue = null
      class TestMutator extends Mutator
        @exec: -> (y) -> calledValue = y

      dom = {}
      (new TestMutator(from.varying(new Varying(8)))).bind(dom)
      calledValue.should.equal(dom)

    it 'should exec() when the value changes', ->
      calledValue = null
      class TestMutator extends Mutator
        @exec: (x) -> -> calledValue = x

      v = new Varying(15)
      m = new TestMutator(from.varying(v))
      m.bind({})
      m.point(match(
        cases.varying (x) -> Varying.ly(x)
        otherwise ->
      ))
      calledValue.should.equal(15)

      v.set(16)
      calledValue.should.equal(16)


    it 'should exec() when repointed or rebound', ->
      calledTimes = 0
      class TestMutator extends Mutator
        @exec: -> -> calledTimes += 1

      m = new TestMutator(from.varying(new Varying(23)))
      m.bind({})
      calledTimes.should.equal(1)

      m.point(match(
        cases.varying (x) -> Varying.ly(x)
        otherwise ->
      ))
      calledTimes.should.equal(2)

      m.bind({})
      calledTimes.should.equal(3)

    it 'should stop exec()ing if stopped', ->
      calledTimes = 0
      class TestMutator extends Mutator
        @exec: -> -> calledTimes += 1

      v = new Varying(42)
      m = new TestMutator(from.varying(v))
      m.bind({})

      m.stop()
      calledTimes.should.equal(1)

      v.set(108)
      calledTimes.should.equal(1)

  describe 'Mutator1', ->
    it 'should apply exec() toplevel with the static param', ->
      calledValue = null
      class TestMutator extends Mutator1
        @exec: (x) -> -> -> calledValue = x

      (new TestMutator(315, from.varying(new Varying(815)))).bind({})
      calledValue.should.equal(315)

    it 'should apply exec() second-level with the value', ->
      calledValue = null
      class TestMutator extends Mutator1
        @exec: -> (x) -> -> calledValue = x

      m = new TestMutator(4, from.varying(new Varying(8)))
      m.bind({})
      m.point(passthrough)
      calledValue.should.equal(8)

    it 'should apply exec() third-level with the binding', ->
      calledValue = null
      class TestMutator extends Mutator1
        @exec: -> -> (x) -> calledValue = x

      dom = {}
      (new TestMutator(15, from.varying(new Varying(16)))).bind(dom)
      calledValue.should.equal(dom)

  describe 'attr', ->
    it 'should call attr on the dom obj correctly', ->
      param = null
      value = null

      dom = { attr: (x, y) -> param = x; value = y }
      m = new mutators.attr('style', from.varying(new Varying('display')))
      m.bind(dom)
      m.point(passthrough)

      param.should.equal('style')
      value.should.equal('display')

    it 'should force the parameter to a string', ->
      value = null

      dom = { attr: (_, x) -> value = x }
      v = new Varying(null)
      m = new mutators.attr('_', from.varying(v))
      m.bind(dom)
      m.point(passthrough)

      v.set(0)
      value.should.equal('0')

      v.set(true)
      value.should.equal('true')

      v.set(null)
      value.should.equal('')

