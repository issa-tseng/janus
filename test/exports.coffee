should = require('should')

{ Library } = require('janus').application
stdlib = require('../lib/janus-stdlib')

describe 'exports', ->
  describe 'view', ->
    it 'should register all components successfully', ->
      l = new Library()
      stdlib.view.registerWith(l)

      registered = false
      registered = true for _ of l.bookcase

