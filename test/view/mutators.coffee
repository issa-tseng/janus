should = require('should')

from = require('../../lib/core/from')
{ match, otherwise } = require('../../lib/core/case')
{ Varying } = require('../../lib/core/varying')
mutators = require('../../lib/view/mutators')


passthrough = match(
  from.default.varying (x) -> Varying.ly(x)
  otherwise ->
)

describe 'Mutator', ->
  describe 'attr', ->
    it 'should call attr on the dom obj correctly', ->
      param = null
      value = null

      dom = { attr: (x, y) -> param = x; value = y }
      mutators.attr('style', from.varying(new Varying('display')))(dom, passthrough)

      param.should.equal('style')
      value.should.equal('display')

    it 'should force the parameter to a string', ->
      value = null

      dom = { attr: (_, x) -> value = x }
      v = new Varying(null)
      mutators.attr(null, from.varying(v))(dom, passthrough)

      v.set(0)
      value.should.equal('0')

      v.set(true)
      value.should.equal('true')

      v.set(null)
      value.should.equal('')

    it 'should return a Varied that can stop mutation', ->
      value = null
      dom = { attr: (_, x) -> value = x }
      v = new Varying(null)
      m = mutators.attr(null, from.varying(v))(dom, passthrough)

      v.set('test')
      value.should.equal('test')

      m.stop()
      v.set('test 2')
      value.should.equal('test')

  describe 'classGroup', ->
    it 'should attempt to add the new class', ->
      addedClass = null
      dom = 
        removeClass: ->
        attr: ->
        addClass: (x) -> addedClass = x

      mutators.classGroup('type-', from.varying(new Varying('test')))(dom, passthrough)

      addedClass.should.equal('type-test')

    it 'should attempt to remove old classes', ->
      removedClasses = []
      dom = 
        removeClass: (x) -> removedClasses.push(x)
        attr: -> 'type-old otherclass some-type-here'
        addClass: ->

      mutators.classGroup('type-', from.varying(new Varying('test')))(dom, passthrough)

      removedClasses.should.eql([ 'type-old' ])

    it 'should return a Varied that can stop mutation', ->
      run = 0
      dom =
        attr: -> ''
        addClass: -> run += 1

      v = new Varying(null)
      m = mutators.classGroup('whatever-', from.varying(v))(dom, passthrough)

      v.set('test')
      run.should.equal(2)

      m.stop()
      v.set('test 2')
      run.should.equal(2)

  describe 'classed', ->
    it 'should call toggleClass with the class name', ->
      className = null
      dom = { toggleClass: (x, _) -> className = x }

      mutators.classed('hide', from.varying(new Varying(true)))(dom, passthrough)

      className.should.equal('hide')

    it 'should call toggleClass with truthiness', ->
      truthy = null
      dom = { toggleClass: (_, x) -> truthy = x }

      v = new Varying('test')
      mutators.classed('hide', from.varying(v))(dom, passthrough)

      truthy.should.equal(false)

      v.set(true)
      truthy.should.equal(true)

      v.set(null)
      truthy.should.equal(false)

    it 'should return a Varied that can stop mutation', ->
      result = null
      dom = { toggleClass: (_, x) -> result = x }

      v = new Varying('test')
      m = mutators.classed('hide', from.varying(v))(dom, passthrough)

      v.set(true)
      result.should.equal(true)
      m.stop()

      v.set(false)
      result.should.equal(true)

  describe 'css', ->
    it 'should call css on the dom obj correctly', ->
      param = null
      value = null

      dom = { css: (x, y) -> param = x; value = y }
      mutators.css('display', from.varying(new Varying('block')))(dom, passthrough)

      param.should.equal('display')
      value.should.equal('block')

    it 'should force the parameter to a string', ->
      value = null

      dom = { css: (_, x) -> value = x }
      v = new Varying(null)
      mutators.css(null, from.varying(v))(dom, passthrough)

      v.set(0)
      value.should.equal('0')

      v.set(true)
      value.should.equal('true')

      v.set(null)
      value.should.equal('')

    it 'should return a Varied that can stop mutation', ->
      value = null
      dom = { css: (_, x) -> value = x }
      v = new Varying(null)
      m = mutators.css(null, from.varying(v))(dom, passthrough)

      v.set('test')
      value.should.equal('test')

      m.stop()
      v.set('test 2')
      value.should.equal('test')

  describe 'text', ->
    it 'should call text on the dom obj correctly', ->
      value = null

      dom = { text: (x) -> value = x }
      mutators.text(from.varying(new Varying('hello')))(dom, passthrough)

      value.should.equal('hello')

    it 'should force the parameter to a string', ->
      value = null

      dom = { text: (x) -> value = x }
      v = new Varying(null)
      mutators.text(from.varying(v))(dom, passthrough)

      v.set(0)
      value.should.equal('0')

      v.set(true)
      value.should.equal('true')

      v.set(null)
      value.should.equal('')

    it 'should return a Varied that can stop mutation', ->
      value = null
      dom = { text: (x) -> value = x }
      v = new Varying(null)
      m = mutators.text(from.varying(v))(dom, passthrough)

      v.set('test')
      value.should.equal('test')

      m.stop()
      v.set('test 2')
      value.should.equal('test')

  describe 'html', ->
    it 'should call html on the dom obj correctly', ->
      value = null

      dom = { html: (x) -> value = x }
      mutators.html(from.varying(new Varying('hello')))(dom, passthrough)

      value.should.equal('hello')

    it 'should force the parameter to a string', ->
      value = null

      dom = { html: (x) -> value = x }
      v = new Varying(null)
      mutators.html(from.varying(v))(dom, passthrough)

      v.set(0)
      value.should.equal('0')

      v.set(true)
      value.should.equal('true')

      v.set(null)
      value.should.equal('')

    it 'should return a Varied that can stop mutation', ->
      value = null
      dom = { html: (x) -> value = x }
      v = new Varying(null)
      m = mutators.html(from.varying(v))(dom, passthrough)

      v.set('test')
      value.should.equal('test')

      m.stop()
      v.set('test 2')
      value.should.equal('test')

