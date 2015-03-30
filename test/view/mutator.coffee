should = require('should')

from = require('../../lib/core/from')
{ Varying } = require('../../lib/core/varying')
{ Mutator, mutators } = require('../../lib/view/mutator')

describe.only 'Mutator', ->
  describe 'base class', ->
    it 'should construct', ->
      (new Mutator(new Varying())).should.be.an.instanceof(Mutator)

    it 'should bind upon calling bind()', ->
      didExec = false
      class TestMutator extends Mutator
        @exec: -> -> didExec = true

      (new TestMutator(from.varying(-> new Varying()))).bind({})
      didExec.should.be.true

