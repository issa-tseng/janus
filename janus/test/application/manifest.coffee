should = require('should')
types = require('../../lib/core/types')
{ Varying } = require('../../lib/core/varying')
{ Manifest } = require('../../lib/application/manifest')
{ App } = require('../../lib/application/app')
{ Model } = require('../../lib/model/model')
from = require('../../lib/core/from')
{ attribute, validate, Trait } = require('../../lib/model/schema')
attributes = require('../../lib/model/attribute')


defer = (f_) -> setTimeout(f_, 0)

class SucceedingRequest
class FailingRequest

failIfTrue = (x) -> (y) ->
  if y is true
    types.validity.error(x)
  else
    types.validity.valid(x)

env = ({ watch = [], resolvers = [], view, trait = Trait() } = {}) ->
  resolving = (inner) -> ->
    result = new Varying()
    resolvers.push(-> result.set(inner))
    result

  TestModel = Model.build(
    attribute('one', attributes.Reference.to(new SucceedingRequest()))
    attribute('two', attributes.Reference.to(new FailingRequest()))
    attribute('three', attributes.Reference.to(new SucceedingRequest()))
    attribute('four', attributes.Reference.to(new FailingRequest()))

    trait
  )

  class TestView
    constructor: (@model) ->
    artifact: -> this.model.get(key).react(->) for key in watch

  app = new App()
  app.views.register(TestModel, view ? TestView)
  app.resolvers.register(SucceedingRequest, resolving(types.result.success('success')))
  app.resolvers.register(FailingRequest, resolving(types.result.failure('failure')))
  app

  { TestModel, TestView, app }


describe 'manifest', ->
  it 'should return a successful view in the simplest case', (done) ->
    result = null
    { TestModel, TestView, app } = env()
    Manifest.run(app, new TestModel()).result.react((x) -> result = x)
    defer ->
      types.result.success.match(result).should.equal(true)
      result.get().should.be.an.instanceof(TestView)
      done()

  it 'should return a fault if a view cannot be found', ->
    result = null
    { app } = env()
    Manifest.run(app, 42).result.react((x) -> result = x)
    types.result.failure.match(result).should.equal(true)
    result.get().should.match(/internal/)

  it 'should wait until pending requests are fulfilled', (done) ->
    result = null
    resolvers = []
    { TestModel, TestView, app } = env({ resolvers, watch: [ 'one', 'two' ] })
    Manifest.run(app, new TestModel()).result.react((x) -> result = x)
    types.result.pending.match(result).should.equal(true)

    defer ->
      types.result.pending.match(result).should.equal(true)
      r() for r in resolvers
      defer ->
        types.result.success.match(result).should.equal(true)
        result.get().should.be.an.instanceof(TestView)
        done()

  it 'should wait for chained requests', (done) ->
    result = null
    resolvers = []
    { TestModel, TestView, app } = env({ resolvers, watch: [ 'one', 'two' ] })
    model = new TestModel()
    model.get('one').react((x) -> model.get('three').react(->) if x?)

    Manifest.run(app, model).result.react((x) -> result = x)

    r() for r in resolvers
    defer ->
      types.result.pending.match(result).should.equal(true)
      resolvers[2]()

      defer ->
        types.result.success.match(result).should.equal(true)
        result.get().should.be.an.instanceof(TestView)
        done()

  it 'should have a record of all resolved requests', (done) ->
    resolvers = []
    { TestModel, TestView, app } = env({ resolvers, watch: [ 'one', 'two' ] })
    m = Manifest.run(app, new TestModel())
    r() for r in resolvers

    defer ->
      m.requests.length_.should.equal(2)
      # technically these /could/ come back in either order but in practice
      # so far they don't.
      m.requests.at_(0).request.should.be.an.instanceof(SucceedingRequest)
      types.result.success.match(m.requests.at_(0).result.get()).should.equal(true)
      m.requests.at_(1).request.should.be.an.instanceof(FailingRequest)
      types.result.failure.match(m.requests.at_(1).result.get()).should.equal(true)
      done()

  it 'should return success if all validations are valid', (done) ->
    result = null
    trait = Trait(
      validate(from('failone').map(failIfTrue()))
      validate(from('failtwo').map(failIfTrue()))
    )
    { TestModel, TestView, app } = env({ trait })
    m = Manifest.run(app, new TestModel())
    m.result.react((x) -> result = x)

    defer ->
      types.result.success.match(result).should.equal(true)
      result.get().should.be.an.instanceof(TestView)
      done()

  it 'should return the failure if an validation is invalid', (done) ->
    result = null
    trait = Trait(
      validate(from('failone').map(failIfTrue(1)))
      validate(from('failtwo').map(failIfTrue(2)))
    )
    { TestModel, TestView, app } = env({ trait })
    m = Manifest.run(app, new TestModel( failone: true ))
    m.result.react((x) -> result = x)

    defer ->
      types.result.failure.match(result).should.equal(true)
      result.get().length_.should.equal(1)
      result.get().at_(0).should.equal(1)
      done()

  it 'should return all failures if many happen', (done) ->
    result = null
    trait = Trait(
      validate(from('failone').map(failIfTrue(1)))
      validate(from('failtwo').map(failIfTrue(2)))
      validate(from('failthree').map(failIfTrue(3)))
    )
    { TestModel, TestView, app } = env({ trait })
    m = Manifest.run(app, new TestModel( failone: true, failthree: true ))
    m.result.react((x) -> result = x)

    defer ->
      types.result.failure.match(result).should.equal(true)
      result.get().length_.should.equal(2)
      result.get().at_(0).should.equal(1)
      result.get().at_(1).should.equal(3)
      done()

  it 'should only result once', (done) ->
    result = null
    resolvers = []
    { TestModel, TestView, app } = env({ resolvers, watch: [ 'one', 'two' ] })
    Manifest.run(app, new TestModel()).result.react((x) -> result = x)

    r() for r in resolvers
    defer ->
      types.result.success.match(result).should.equal(true)
      firstResult = result

      r() for r in resolvers
      defer ->
        result.should.equal(firstResult)
        done()

  it 'should function as a resolving Thenable', ->
    { TestModel, TestView, app } = env()
    Manifest.run(app, new TestModel())
      .should.be.resolved()
      .then((result) ->
        result.should.be.an.instanceOf(TestView)
      )

  it 'should function as a rejecting Thenable', ->
    trait = Trait(
      validate(from('failone').map(failIfTrue(1)))
      validate(from('failtwo').map(failIfTrue(2)))
    )
    { TestModel, TestView, app } = env({ trait })
    m = Manifest.run(app, new TestModel( failone: true ))
      .should.be.rejected()
      .then((errors) ->
        errors.list.should.eql([ 1 ])
      )

  it 'should isolate its own App events', (done) ->
    result = null
    resolvers = []
    { TestModel, TestView, app } = env({ resolvers, watch: [ 'one' ] })
    Manifest.run(app, new TestModel()).result.react((x) -> result = x)
    Manifest.run(app, new TestModel())

    resolvers.length.should.equal(2)
    resolvers[0]()
    defer ->
      types.result.success.match(result).should.equal(true)
      done()

