should = require('should')

Model = require('../../lib/model/model').Model
View = require('../../lib/view/view').View

describe 'View', ->
  describe 'core', ->
    it 'should call initialize on instantiation if it exists', ->
      called = false
      class TestView extends View
        _initialize: -> called = true

      new TestView()
      called.should.equal(true)

  describe 'ViewModel injection', ->
    it 'should use the subject directly if no ViewModel is defined', ->
      class NoViewModel extends View
      class MyModel extends Model

      model = new MyModel()
      view = new NoViewModel(model)

      view.subject.should.equal model

    it 'should wrap in ViewModel if a ViewModel is defined', ->
      class MyViewModel extends Model
      class WithViewModel extends View
        @viewModelClass: MyViewModel

      class MyModel extends Model

      model = new MyModel()
      view = new WithViewModel(model)

      view.subject.should.be.an.instanceof MyViewModel
      view.subject.get('subject').should.equal model

  describe 'artifact handling', ->
    it 'should get its artifact from _render', ->
      artifact = {}
      class TestView extends View
        _render: -> artifact

      (new TestView()).artifact().should.equal(artifact)

    it 'should only ever call _render once', ->
      called = 0
      artifact = {}
      class TestView extends View
        _render: ->
          called += 1
          artifact

      view = new TestView()
      view.artifact().should.equal(artifact)
      view.artifact().should.equal(artifact)
      called.should.equal(1)

    describe 'event wiring', ->
      it 'should call _wireEvents', ->
        called = false
        class TestView extends View
          _wireEvents: -> called = true

        (new TestView()).wireEvents()
        called.should.equal(true)

      it 'should call _wireEvents only once', ->
        called = 0
        class TestView extends View
          _wireEvents: -> called += 1

        view = new TestView()
        view.wireEvents()
        view.wireEvents()
        called.should.equal(1)

