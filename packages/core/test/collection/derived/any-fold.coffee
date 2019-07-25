should = require('should')

Model = require('../../../lib/model/model').Model

Varying = require('../../../lib/core/varying').Varying
{ List } = require('../../../lib/collection/list')
{ AnyFold } = require('../../../lib/collection/derived/any-fold')
{ any } = AnyFold

describe 'collection', ->
  describe 'any fold', ->
    # we don't really aim to fully test every case here since AnyFold just
    # synthesizes flatMap and includes. we just test that the glue is right.

    describe 'without map', ->
      it 'should init to true if any trues exist', ->
        (new List([ false, false, true ])).any().get().should.equal(true)
        (new List([ false, false ])).any().get().should.equal(false)

        resultA = null
        (new List([ false, true, false ])).any().react((value) -> resultA = value)
        resultA.should.equal(true)

        resultB = null
        (new List([ false, false ])).any().react((value) -> resultB = value)
        resultB.should.equal(false)

      it 'should react as the list changes', ->
        list = new List()

        result = null
        list.any().react((value) -> result = value)
        result.should.equal(false)

        list.add(false)
        result.should.equal(false)
        list.add(42)
        result.should.equal(false)
        list.add(true)
        result.should.equal(true)
        list.remove(true)
        result.should.equal(false)

      it 'should not destroy the plain list on destroy', ->
        events = 0
        destroying = false
        list = new List()
        list.on('added', -> events += 1)
        list.on('destroying', -> destroying = true)

        list.add(false)
        events.should.equal(1)

        o = list.any().react(->)
        o.stop()
        destroying.should.equal(false)

        list.add(true)
        events.should.equal(2)

    describe 'with map', ->
      it 'should init to true if any trues exist', ->
        map = (x) -> x is 42
        (new List([ false, true, 42 ])).any(map).get().should.equal(true)
        (new List([ false, true ])).any(map).get().should.equal(false)

        resultA = null
        (new List([ false, true, 42 ])).any(map).react((value) -> resultA = value)
        resultA.should.equal(true)

        resultB = null
        (new List([ false, true ])).any(map).react((value) -> resultB = value)
        resultB.should.equal(false)

      it 'should react as the list changes', ->
        list = new List()

        result = null
        list.any((x) -> x is 42).react((value) -> result = value)
        result.should.equal(false)

        list.add(false)
        result.should.equal(false)
        list.add(true)
        result.should.equal(false)
        list.add(42)
        result.should.equal(true)
        list.remove(42)
        result.should.equal(false)

