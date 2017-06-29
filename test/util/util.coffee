should = require('should')

util = require('../../lib/util/util')

describe 'Util', ->
  describe 'isArray', ->
    it 'should return true only for arrays', ->
      util.isArray([]).should.equal(true)
      util.isArray(arguments).should.equal(false)
      util.isArray({}).should.equal(false)
      util.isArray(null).should.equal(false)

  describe 'isNumber', ->
    it 'should return true only for numbers', ->
      util.isNumber(1).should.equal(true)
      util.isNumber(1.1).should.equal(true)
      util.isNumber(NaN).should.equal(false)
      util.isNumber(null).should.equal(false)

  describe 'isPlainObject', ->
    it 'should return true only for plain objects', ->
      util.isPlainObject({}).should.equal(true)
      util.isPlainObject({ test: 1 }).should.equal(true)

      util.isPlainObject([]).should.equal(false)
      util.isPlainObject(0).should.equal(false)
      util.isPlainObject(true).should.equal(false)
      util.isPlainObject('test').should.equal(false)
      class TestClass
      util.isPlainObject(new TestClass()).should.equal(false)
      util.isPlainObject(null).should.equal(false)

  describe 'isPrimitive', ->
    it 'should return true only for strings, numbers, and booleans', ->
      util.isPrimitive('test').should.equal(true)
      util.isPrimitive(0).should.equal(true)
      util.isPrimitive(true).should.equal(true)
      util.isPrimitive(false).should.equal(true)

      util.isPrimitive(null).should.equal(false)
      util.isPrimitive({}).should.equal(false)
      util.isPrimitive([]).should.equal(false)

  describe 'uniqueId', ->
    it 'should return monotonically increasing numbers', ->
      last = -1
      next = (cur) ->
        cur.should.be.a.Number
        (cur > last).should.equal(true)
        last = cur

      next(util.uniqueId())
      next(util.uniqueId())
      next(util.uniqueId())
      next(util.uniqueId())

  describe 'capitalize', ->
    it 'should capitalize the very first letter', ->
      util.capitalize('test').should.equal('Test')
      util.capitalize('x').should.equal('X')
      should.doesNotThrow(-> util.capitalize(null))

  describe 'fix', ->
    it 'should perform fixed point recursion', ->
      # with thanks to prelude-ls.
      (util.fix((fib) -> (n) -> if n <= 1 then 1 else fib(n - 1) + fib(n - 2)))(10).should.equal(89)

  describe 'identity', ->
    it 'should be too silly to test', ->
      sentinel = {}
      util.identity(sentinel).should.equal(sentinel)

  describe 'foldLeft', ->
    it 'should fold with an initial value and a recurring folder', ->
      util.foldLeft('this')([ 'is', 'only', 'a', 'test' ], (x, y) -> "#{x} #{y}").should.equal('this is only a test')

  describe 'reduceLeft', ->
    it 'should fold without taking an initial value', ->
      util.reduceLeft([ 'this', 'is', 'only', 'a', 'test' ], (x, y) -> "#{x} #{y}").should.equal('this is only a test')

  describe 'extend', ->
    it 'should copy properties from the sources onto the target', ->
      target = { a: 1 }
      should(util.extend(target, { b: 2, c: 3 }, { d: 4, e: 5})).equal(null)
      target.should.eql({ a: 1, b: 2, c: 3, d: 4, e: 5 })

  describe 'extendNew', ->
    it 'should copy properties from the sources onto a new object', ->
      util.extendNew({ a: 1 }, { b: 2, c: 3 }, { d: 4, e: 5}).should.eql({ a: 1, b: 2, c: 3, d: 4, e: 5 })

  describe 'isEmptyObject', ->
    it 'should return true only for plain, empty objects', ->
      util.isEmptyObject(null).should.equal(false)
      util.isEmptyObject({ test: 1 }).should.equal(false)
      util.isEmptyObject({}).should.equal(true)

  describe 'superclass', ->
    it 'should correctly identify the superclass of a coffeescript class', ->
      class A
      class B extends A
      util.superClass(B).should.equal(A)

    it 'should correctly identify the superclass of a livescript class', ->
      # compiled livescript:
      `var A, B;
      A = (function(){
        A.displayName = 'A';
        var prototype = A.prototype, constructor = A;
        function A(){}
        return A;
      }());
      B = (function(superclass){
        var prototype = extend$((import$(B, superclass).displayName = 'B', B), superclass).prototype, constructor = B;
        function B(){
          B.superclass.apply(this, arguments);
        }
        return B;
      }(A));
      function extend$(sub, sup){
        function fun(){} fun.prototype = (sub.superclass = sup).prototype;
        (sub.prototype = new fun).constructor = sub;
        if (typeof sup.extended == 'function') sup.extended(sub);
        return sub;
      }
      function import$(obj, src){
        var own = {}.hasOwnProperty;
        for (var key in src) if (own.call(src, key)) obj[key] = src[key];
        return obj;
      }`

      util.superClass(B).should.equal(A)

  describe 'deepGet', ->
    it 'should work with dot syntax', ->
      util.deepGet({ a: { b: { c: 2 } } }, 'a.b.c').should.equal(2)
      util.deepGet({ a: { b: { c: { d: 3 } } } }, 'a.b.c').should.eql({ d: 3 })

    it 'should work with an array', ->
      util.deepGet({ a: { b: { c: 2 } } }, [ 'a', 'b', 'c' ]).should.equal(2)

    it 'should work with a number', ->
      util.deepGet({ 11: 38 }, 11).should.equal(38)

    it 'should return null if the key is not found', ->
      should(util.deepGet({}, 'a.b.c')).equal(null)

  describe 'deepSet', ->
    it 'should return a function', ->
      util.deepSet({}, 'a.b.c').should.be.a.Function

    it 'should set the requested key when the second order function is called', ->
      obj = {}
      util.deepSet(obj, 'a.b.c')(2)
      obj.should.eql({ a: { b: { c: 2 } } })

    it 'should work with a number', ->
      obj = {}
      util.deepSet(obj, 11)(38)
      obj.should.eql({ 11: 38 })

  describe 'deepDelete', ->
    it 'should delete a deep value and return the deleted value', ->
      obj = { a: { b: { c: 2, d: 3 } } }
      util.deepDelete(obj, 'a.b.c').should.equal(2)
      obj.should.eql({ a: { b: { d: 3 } } })

    it 'should return null if the key does not exist', ->
      obj = {}
      should(util.deepDelete(obj, 'a.b.c')).equal(undefined)
      obj.should.eql({})

    it 'should not fail if the last step does not exist', ->
      obj = { a: { b: { c: null } } }
      should(util.deepDelete(obj, 'a.b.c.d')).equal(undefined)
      obj.should.eql({ a: { b: { c: null } } })

  describe 'traverse', ->
    it 'should traverse every leaf', ->
      traversed = []
      util.traverse({ a: { b: { c: 2, d: 3 }, e: 4 } }, (k, v) -> traversed.push(k.join('.')); traversed.push(v))
      traversed.should.eql([ 'a.b.c', 2, 'a.b.d', 3, 'a.e', 4 ])

  describe 'traverseAll', ->
    it 'should traverse every node', ->
      traversed = []
      util.traverseAll({ a: { b: { c: 2, d: 3 }, e: 4 } }, (k, v) -> traversed.push(k.join('.')); traversed.push(v))
      traversed.should.eql([
        'a', { b: { c: 2, d: 3 }, e: 4 },
        'a.b', { c: 2, d: 3 },
        'a.b.c', 2,
        'a.b.d', 3,
        'a.e', 4
      ])

