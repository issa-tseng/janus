Major Changelog
===============

## [0.5](https://github.com/clint-tseng/janus/compare/0.4...0.5)

With the exception of Collection folds, rework everything in the framework that still felt half-baked, iffy, or dangerous. Many small renamings and major refactors of core components.

* New features:
    * `View#attach()` now works; given a data tree and DOM tree previously rendered by (eg server-side) Janus, instantiates a new View tree and binds it against all the existing DOM points.
* Refactors:
    * Redid entire `application` package:
        * `Library` no longer auto-instantiates things it hands back. Also simplified call format to remove the explicit `attributes` object. `acceptor` and `rejector` are no longer supported.
        * `Endpoint`, `Handler`, and `Manifest` got all simplified and collapsed down to just `Manifest`. Actually gained some features in this process.
        * `App` got simplified as well, primarily because it no longer shadow-copies with each returned artifact and no longer worries about Stores so much. Almost all the "automagic" in the framework is now contained within `App`.
        * All three are now top-level exports in the Janus package.
    * Reworked implementation behind `from` and `case` core components:
        * `from` didn't really change externally except that the semantics around transforming a `from` to a `Varying` is now concretely whenever `.point()` is called. Removed all the complicated internal casing.
        * `case` no longer typechecks full case set on `match` which makes it a simple tight loop. It also once again relies on `instanceof` and class instances. Generally much more pleasant to look at.
    * Request/Resolve got reworked one last time:
        * Resolvers are now just simple functions (req) -> Varying[types.result[x]] rather than class instances.
        * `Model` barely knows about request resolution anymore; all it has is an `autoResolveWith(app)` which routes that app to all resolving attributes it owns.
        * All the magic around setting request results into the Model now live on the `ReferenceAttribute` itself, which feels cleaner.
    * `Set` was completely reimplemented and now provides much-closer-to true Set semantics.
    * `Model` issues/validate moved around a little bit; their names make more sense now.
    * `Base` no longer derives from `EventEmitter2`; it lazily instantiates one when it needs it.
* Quality of life improvements:
    * We now support `Varying.all([ vx, vy, vz ]).react((x, y, z) -> …)` to directly react on multiple Varyings.
    * In ES6, we now allow `for (const x of list)` where list is a Janus `List`.
* Fixes:
    * General audit for memory leaks and accidental returns.
    * No longer rely on a global singleton (commit to peerDependencies on NPM).
    * ES6 classtree detection now works for subtle corner cases.

## [0.4](https://github.com/clint-tseng/janus/compare/0.3.1...0.4)

Once again focused on two things. First, a huge number of small-scale quality of life improvements were implemented to provide better answers for awkward syntactical constructions and codify some common-in-practice patterns into simpler forms. Secondly, as part of an important effort to ensure broad language compatibility, the Model and DomView declaration systems were entirely refactored to move away from class-based definition, which were tightly bound with Coffeescript's classdef particulars. The new system also improves behavioural composition.

* Quality of life improvements:
    * Make `.react()` do what `.reactNow()` used to do, as it is the more common call. `reactLater` replaces the old `react`.
    * `from(…).asVarying()` will now get you an unflat `Varying` mapping argument, in case it is better for performance, eg when creating things like filtered lists.
    * Add `varying.pipe()` which makes stdlib Varying helpers easier to use; eg: `varying.map(…).pipe(throttle(30)).react(…)`.
    * Allow `from.app('key')` to watch the given key. Previously, no arguments were taken.
    * Add a curried form of `map.set('key')` which returns a function which sets that k/v data.
    * `map.with({ attrs })` shortcut to shadow a Map with the given data override.
    * `default()` and `transient()` Model attribute declaration shortcuts.
* Big refactors:
    * Rather than declaring a class with `@_dom` and `@_template` to create a DomView, the new `DomView.build(dom, template)` facility takes a DOM fragment and a `template()` and [constructs a DomView](https://github.com/clint-tseng/janus-samples/blob/master/todo/src/view/todo-list.coffee).
        * Template mutator definitions can now chain, eg `find('.title').text(from('name')).classed('active', from('enabled'))`. This works even with interally-chaining mutators like `.render()`
        * The new `.on()` declaration isn't technically an idempotent mutator like the others but enables much quicker event wiring definition without having to write a full `_wireEvents` method.
    * `Model` no longer has classdef methods `@attribute` and `@bind`. Now these are declared via `Model.build(…)`.
        * `attribute`, `bind`, `issue`, `default`, and `transient` are top-level package exports that can be used in `Model.build(…)` to define the Model.
        * Class-based inheritance still works if so desired.
        * But preferred is the new Trait system, which is essentially `template()` but for `Model`s, enabling eg `Model.build(TraitA, TraitB, bind(…), attribute(…))`. Traits may contain other Traits. Last write wins.

## [0.3](https://github.com/clint-tseng/janus/compare/0.2...0.3)

Focused on two major areas: unbundling and formalizing models as data structures and enumeration/traversal of data structures; and resource lifecycle management. Also improved request/store handling, updated dependencies, and improved test coverage overall.

* Unbundled `Model` into `Map` and `Model`, and moved `Map` into the `collections` package.
    * `Map` gets all core functionality around key/value storage, basic (de)serialization, and shadowing.
    * `Model` derives from `Map`; it retains attribute definition, issue tracking, attribute binding, request resolution, and more-advanced (de)serialization features.
* `Map`, now more of a data structure, derives from the new `Enumerable` trait along with `List`. Enumerability covers the following basic features:
    * Static enumeration via `enumerate` and live enumeration via `enumeration`, which provide all keys (string keys in the case of `Map` and integer indices in the case of `List`) as either an `Array` or `List`, respectively. Live enumerations then provide `mapPairs` and `flatMapPairs`, which provide `(k, v)` arguments to a mapping function.
    * Serialization via traversal (see below) on a static enumeration.
    * Diff tracking via traversal (ditto), which tracks differences between arbitrary data structures and provides a `Varying[Boolean]` signalling as such. Modification tracking is now just diff tracking against an object's shadow parent.
* `Traversal` provides a principled way to recursively walk a data structure tree and map the result onto a like-structured result or into a reducible `List`. Default serialization and default diff tracking are implemented in terms of `Traversal`, such that their behaviour can easily be overridden piecemeal deep into a structure.
* Resource management becomes much more automatic and memory-safe:
    * `Varying` gets `refCount`, enabling resources or processing to be spun up and down as necessary.
    * `Varying` also gets `managed`, in the case that a `Varying` return value depends on intermediate calculated `Base` objects. With `managed`, the intermediate resources are automatically generated when the `Varying` is actually active, and destroyed when it is not.
    * `Base` gets a similar `managed`, but instead of managing intermediate resources is concerned with being able to share read-only computed resources like `Enumeration`s. Methods like `.enumerate()` can depend on `Base.managed` to vend one shared resource that is spun up or down as needed and destroyed.
    * The request handling code is upgraded to use these new features.
* `Varying` got a huge internal refactor to cut down significantly on memory and processing usage, and eliminate classes of race condition bugs that became a big problem with the addition of `refCount`.
* `Request` and `Store` get upgraded with better handling, new and more consistent APIs, and full test coverage.
* The casing system was upgraded with global attributes, case arity, and case subclassing.


## [0.2](https://github.com/clint-tseng/janus/compare/0.1...0.2)

Completely overhauled and rewrote the `Varying` abstraction, as well as much of the templating, view, model, and collections systems that were too tightly-bound to `Varying` to escape rewrite. Introduced `case` and `from` as vital core abstractions. Also dramatically increased test coverage, streamlined and removed a bunch of fluff components, and other miscellenia.

* `Varying` became a true monad: it no longer automatically flattens its contents. It also no longer uses an event-based system for change propagation, as this resulted in intractable race condition problems as well as performance issues. Many improvements and changes aren't listed here.
* The `case` system is new, and an attempt to formalize and abstract the internal behaviour-handling models of Janus such that they can be easily augmented or replaced in userland where needed. It is a response to the problems with `instanceof`-based casing.
* The `from` system is a reconsideration of how databinding can be declared and executed. Its point-free programming model enables it to be freely leveraged to solve any number of problems unrelated to databinding.
* `Mutator` and `Template` are ground-up reconsiderations of how to bundle template-like behaviour.
* `View` and `Model` are impacted insofar as their interfaces to the above are concerned.
* Alongside this release is the new [`janus-stdlib`](https://github.com/clint-tseng/janus-stdlib), which contains a slew of very useful default View implementations for the objects in the library.

## 0.1

Initial release. All the basics are here, but given that the philosophy codified alongside the development, the exposed API is less than precise and often in conflict with the underlying machinations.

