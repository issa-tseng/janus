return
should = require('should')

Model = require('../../lib/model/model').Model
View = require('../../lib/view/view').View

describe 'View', ->
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

