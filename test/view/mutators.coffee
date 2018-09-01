should = require('should')

from = require('../../lib/core/from')
types = require('../../lib/core/types')
{ match, otherwise } = require('../../lib/core/case')
{ Varying } = require('../../lib/core/varying')
mutators = require('../../lib/view/mutators')

# TODO: no tests for from.[...].all, only from.x directly.

passthrough = match(
  types.from.varying (x) -> Varying.of(x)
  otherwise ->
)
passthroughWithApp = (given) ->
  match(
    types.from.app -> Varying.of(given)
    otherwise (x) -> passthrough(x)
  )
passthroughWithSelf = (given) ->
  match(
    types.from.self -> Varying.of(given)
    otherwise (x) -> passthrough(x)
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

    it 'should return an Observation that can stop mutation', ->
      value = null
      dom = { attr: (_, x) -> value = x }
      v = new Varying(null)
      m = mutators.attr(null, from.varying(v))(dom, passthrough)

      v.set('test')
      value.should.equal('test')

      m.stop()
      v.set('test 2')
      value.should.equal('test')

    it 'should react non-immediately if requested', ->
      value = null
      dom = { attr: (_, x) -> value = x }
      v = new Varying('test')
      mutators.attr(null, from.varying(v))(dom, passthrough, false)

      (value is null).should.equal(true)

      v.set('test 2')
      value.should.equal('test 2')

  describe 'classGroup', ->
    it 'should attempt to add the new class', ->
      setClass = null
      dom = { attr: (x, y) -> x.should.equal('class'); setClass = y }

      mutators.classGroup('type-', from.varying(new Varying('test')))(dom, passthrough)
      setClass.should.equal('type-test')

    it 'should attempt to remove old classes', ->
      setClass = null
      dom = { attr: (x, y) -> setClass = y; 'type-old otherclass some-type-here' }

      mutators.classGroup('type-', from.varying(new Varying('test')))(dom, passthrough)
      setClass.should.eql('otherclass some-type-here type-test')

    it 'should return an Observation that can stop mutation', ->
      run = 0
      dom = { attr: -> run += 1; '' }

      v = new Varying(null)
      m = mutators.classGroup('whatever-', from.varying(v))(dom, passthrough)

      v.set('test')
      run.should.equal(4)

      m.stop()
      v.set('test 2')
      run.should.equal(4)

    it 'should react non-immediately if requested', ->
      value = null
      dom = { attr: ((x, y) -> value = y) }
      v = new Varying('test')
      m = mutators.classGroup('test-', from.varying(v))(dom, passthrough, false)

      (value is null).should.equal(true)

      v.set('test2')
      value.should.equal('test-test2')

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

    it 'should return an Observation that can stop mutation', ->
      result = null
      dom = { toggleClass: (_, x) -> result = x }

      v = new Varying('test')
      m = mutators.classed('hide', from.varying(v))(dom, passthrough)

      v.set(true)
      result.should.equal(true)
      m.stop()

      v.set(false)
      result.should.equal(true)

    it 'should react non-immediately if requested', ->
      className = null
      dom = { toggleClass: (x, _) -> className = x }

      v = new Varying(true)
      mutators.classed('hide', from.varying(v))(dom, passthrough, false)
      (className is null).should.equal(true)

      v.set(false)
      className.should.equal('hide')

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

    it 'should return an Observation that can stop mutation', ->
      value = null
      dom = { css: (_, x) -> value = x }
      v = new Varying(null)
      m = mutators.css(null, from.varying(v))(dom, passthrough)

      v.set('test')
      value.should.equal('test')

      m.stop()
      v.set('test 2')
      value.should.equal('test')

    it 'should react non-immediately if requested', ->
      value = null

      dom = { css: (_, y) -> value = y }
      v = new Varying('block')
      mutators.css('display', from.varying(v))(dom, passthrough, false)
      (value is null).should.equal(true)

      v.set('inline')
      value.should.equal('inline')

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

    it 'should return an Observation that can stop mutation', ->
      value = null
      dom = { text: (x) -> value = x }
      v = new Varying(null)
      m = mutators.text(from.varying(v))(dom, passthrough)

      v.set('test')
      value.should.equal('test')

      m.stop()
      v.set('test 2')
      value.should.equal('test')

    it 'should react non-immediately if requested', ->
      value = null
      dom = { text: (x) -> value = x }
      v = new Varying('test')
      mutators.text(from.varying(v))(dom, passthrough, false)
      (value is null).should.equal(true)

      v.set('test 2')
      value.should.equal('test 2')

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

    it 'should return an Observation that can stop mutation', ->
      value = null
      dom = { html: (x) -> value = x }
      v = new Varying(null)
      m = mutators.html(from.varying(v))(dom, passthrough)

      v.set('test')
      value.should.equal('test')

      m.stop()
      v.set('test 2')
      value.should.equal('test')

    it 'should react non-immediately if requested', ->
      value = null
      dom = { html: (x) -> value = x }
      v = new Varying('test')
      mutators.html(from.varying(v))(dom, passthrough, false)
      (value is null).should.equal(true)

      v.set('test 2')
      value.should.equal('test 2')

  describe 'prop', ->
    it 'should call prop on the dom obj correctly', ->
      param = null
      value = null

      dom = { prop: (x, y) -> param = x; value = y }
      mutators.prop('style', from.varying(new Varying('display')))(dom, passthrough)

      param.should.equal('style')
      value.should.equal('display')

    it 'should not coerce values to a string', ->
      param = null
      value = null

      dom = { prop: (x, y) -> param = x; value = y }
      mutators.prop('checked', from.varying(new Varying(true)))(dom, passthrough)

      param.should.equal('checked')
      value.should.equal(true)

    it 'should return an Observation that can stop mutation', ->
      param = null
      value = null

      dom = { prop: (x, y) -> param = x; value = y }
      v = new Varying(true)
      m = mutators.prop('checked', from.varying(v))(dom, passthrough)

      param.should.equal('checked')
      value.should.equal(true)

      m.stop()
      v.set(false)
      value.should.equal(true)

    it 'should react non-immediately if requested', ->
      value = null
      dom = { prop: (_, x) -> value = x }
      v = new Varying('test')
      mutators.prop('prop', from.varying(v))(dom, passthrough, false)
      (value is null).should.equal(true)

      v.set('test 2')
      value.should.equal('test 2')

  describe 'render', ->
    it 'passes the subject to the library', ->
      subject = null
      dom = { append: (->), empty: (->), data: (->), children: (->) }
      app = { view: (x) -> subject = x; { artifact: (->) } }
      point = passthroughWithApp(app)

      mutators.render(from.varying(new Varying(1)))(dom, point)
      subject.should.equal(1)

    it 'passes bare context to the library if provided', ->
      subject = null
      context = null
      dom = { append: (->), empty: (->), data: (->), children: (->) }
      app = { view: (x, opts) -> subject = x; context = opts.context; { artifact: (->) } }
      point = passthroughWithApp(app)

      mutators
        .render(from.varying(new Varying(1)))
        .context('edit')(dom, point)
      subject.should.equal(1)
      context.should.equal('edit')

    it 'passes varying context to the library if provided', ->
      subject = null
      context = null
      dom = { append: (->), empty: (->), data: (->), children: (->) }
      app = { view: (x, opts) -> subject = x; context = opts.context; { artifact: (->) } }
      point = passthroughWithApp(app)

      mutators
        .render(from.varying(new Varying(1)))
        .context(from.varying(new Varying('edit')))(dom, point)
      subject.should.equal(1)
      context.should.equal('edit')

    # also checks for appropriate context merging.
    it 'passes bare criteria options to the library if provided', ->
      opts = null
      dom = { append: (->), empty: (->), data: (->), children: (->) }
      app = { view: (x, y) -> opts = y; { artifact: (->) } }
      point = passthroughWithApp(app)

      mutators
        .render(from.varying(new Varying(1)))
        .context('edit')
        .criteria({ attrs: 2 })(dom, point)
      opts.attrs.should.equal(2)
      opts.context.should.equal('edit')

    # also checks for appropriate criteria merging.
    it 'passes constructor options to the app if provided', ->
      criteria = null
      opts = null
      dom = { append: (->), empty: (->), data: (->), children: (->) }
      app = { view: (x, y, z) -> criteria = y; opts = z; { artifact: (->) } }
      point = passthroughWithApp(app)

      mutators
        .render(from.varying(new Varying(1)))
        .criteria({ attrs: 2 })
        .options({ test: 3 })(dom, point)
      criteria.attrs.should.equal(2)
      opts.should.eql({ test: 3 })

    it 'clears out the previous subview', ->
      views = []
      emptied = 0
      dom = { append: (->), empty: (-> emptied += 1), data: (->), children: (->) }
      view = -> { artifact: (-> dom), destroy: -> (this.destroyed = true) }
      app = { view: -> (v = view(); views.push(v); v) }
      point = passthroughWithApp(app)

      varying = new Varying(1)
      mutators.render(from.varying(varying))(dom, point)

      varying.set(2)
      views.length.should.equal(2)
      views[0].destroyed.should.equal(true)
      emptied.should.equal(2)

      varying.set(3)
      views.length.should.equal(3)
      views[1].destroyed.should.equal(true)
      emptied.should.equal(3)

      (views[2].destroyed is true).should.equal(false)

    it 'drops in the new subview', ->
      appended = null
      newView = { artifact: -> 4 }
      dom = { append: ((x) -> appended = x), empty: (->), children: (->) }
      app = { view: (-> newView) }
      point = passthroughWithApp(app)

      mutators.render(from.varying(new Varying(1)))(dom, point)
      appended.should.equal(4)

    it 'should return an Observation that can stop mutation', ->
      value = null
      dom = { append: ((x) -> value = x), empty: (->), data: (->), children: (->) }
      app = { view: (x) -> { artifact: -> x } }
      point = passthroughWithApp(app)

      v = new Varying(1)
      m = mutators.render(from.varying(v))(dom, point)
      value.should.equal(1)

      m.stop()
      v.set(2)
      value.should.equal(1)

    it 'should attach instead of render the child view if reacting non-immediately', ->
      attached = null
      newView = { attach: (x) -> attached = x }
      dom = { children: (-> { length: 1, _test: 42 }) }
      app = { view: (-> newView) }
      point = passthroughWithApp(app)

      mutators.render(from.varying(new Varying(1)))(dom, point, false)
      attached._test.should.equal(42)

    it 'should render instead of attach if nothing is there', ->
      emptied = false
      appended = null
      dom = { append: ((x) -> appended = x), empty: (-> emptied = true), data: (->), children: -> { length: 0 } }
      app = { view: (x) -> { artifact: -> x } }
      point = passthroughWithApp(app)

      v = new Varying(1)
      m = mutators.render(from.varying(v))(dom, point)
      emptied.should.equal(true)
      appended.should.equal(1)

    it 'should render instead of attach upon a second mutation', ->
      attached = appended = null
      emptied = false
      view = -> { attach: ((x) -> attached = x), artifact: (-> 8), destroy: (->) }
      dom = { children: (-> { length: 1, _test: 42 }), empty: (-> emptied = true), append: ((x) -> appended = x) }
      app = { view }
      point = passthroughWithApp(app)

      v = new Varying(1)
      m = mutators.render(from.varying(v))(dom, point, false)
      attached._test.should.equal(42)
      emptied.should.equal(false)
      (appended is null).should.equal(true)

      v.set(2)
      emptied.should.equal(true)
      appended.should.equal(8)

  describe 'on', ->
    it 'should do nothing initially', ->
      called = false
      fired = false
      dom = { on: (-> called = true) }
      mutators.on('click', (-> fired = true))(dom, passthroughWithSelf({}))
      called.should.equal(false)
      fired.should.equal(false)

    it 'should start listening on the dom node when start() is called', ->
      called = false
      fired = false
      dom = { on: (-> called = true) }
      binding = mutators.on('click', (-> fired = true))(dom, passthroughWithSelf({}))
      binding.start()
      called.should.equal(true)
      fired.should.equal(false)

    it 'should register the listener with the appropriate parameters', ->
      calledWith = []
      dom = { on: ((xs...) -> calledWith.push(xs)) }
      binding = mutators.on('click', '.selector', 42, (-> fired = true))(dom, passthroughWithSelf({}))
      binding.start()
      calledWith.length.should.equal(1)
      calledWith[0].length.should.equal(4)
      calledWith[0][0].should.equal('click')
      calledWith[0][1].should.equal('.selector')
      calledWith[0][2].should.equal(42)
      calledWith[0][3].should.be.a.Function()

    it 'should call the handler with the appropriate arguments when fired', ->
      handler = null
      firedWith = []
      dom = { on: ((event, cb) -> handler = cb) }
      view = { subject: {}, artifact: (-> dom) }
      binding = mutators.on('click', ((xs...) -> firedWith.push(xs)))(dom, passthroughWithSelf(view))
      binding.start()

      event = {}
      handler(event)
      firedWith.should.eql([[ event, view.subject, view, dom ]])

    # had a bug where accidental reuse/mutation of args caused crosstalk:
    it 'should work multiple times independently', ->
      subjects = []
      dommer = -> { on: (_, cb) -> this.cb = cb }
      m = mutators.on('click', (_, subject) -> subjects.push(subject))

      domA = dommer()
      m(domA, passthroughWithSelf({ artifact: (-> domA), subject: 'a' })).start()
      domB = dommer()
      m(domB, passthroughWithSelf({ artifact: (-> domB), subject: 'b' })).start()

      domB.cb()
      domA.cb()

      subjects.should.eql([ 'b', 'a' ])

    it 'should stop the listener when the binding is stopped', ->
      calledOn = false
      calledOff = false
      dom = { on: (-> calledOn = true), off: (-> calledOff = true) }
      binding = mutators.on('click', (->))(dom, passthroughWithSelf({}))
      binding.start()
      calledOn.should.equal(true)
      calledOff.should.equal(false)
      binding.stop()
      calledOff.should.equal(true)

    it 'should stop the binding when stop() is called', ->
      dom = { on: (->), off: (->) }
      v = new Varying({})
      binding = mutators.on('click', (->))(dom, passthroughWithSelf(v))
      binding.start()
      oldStart = binding.start
      binding.stop()
      v.set({})
      binding.start.should.equal(oldStart)

  describe 'all-terminated froms', ->
    it 'should work if passed an all-terminated from', ->
      value = null
      dom = { text: ((x) -> value = x) }
      mutators.text(
        from.varying(new Varying(2))
          .and.varying(new Varying(3))
          .all.map((a, b) -> a + b)
      )(dom, passthrough)

      value.should.equal('5')

    it 'should work in chains if passed an all-terminated from', ->
      subject = null
      context = null
      dom = { append: (->), empty: (->), data: (->), children: (->) }
      app = { view: (x, opts) -> subject = x; context = opts.context; { artifact: (->) } }
      point = passthroughWithApp(app)

      mutators
        .render(from.varying(new Varying(1)).all)
        .context(from.varying(new Varying('edit')).all)(dom, point)
      subject.should.equal(1)
      context.should.equal('edit')

