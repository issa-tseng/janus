Janus
=====

Janus is a library-framework designed to simplify web application flow through the application of FRP and reactive programming principles. It was conceived in order to facilitate applications that could be freely rendered server- and client-side from a single codebase -- the dedication to purely functional userland code and idempotent rendering/templating operations arose as a natural outcome of this goal. This is not a complete application framework -- it contains many of the relevant building blocks, but needs to be supplemented with, amongst other things, a DOM manipulation library like jQuery, and a web application server like Express or Flatiron.

Janus is different from other FRP frameworks in two predominant ways: it is meant to look familiar and friendly to application programmers with a background writing traditional Javascript web applications, and it eschews any desire to model streams of events and signals over time, instead concentrating on providing easy, stateless mappings from the current state of the system to the UI. It does so through pragmatic purity -- in cases where imperative code can be made perfectly clear and side effects are inconsequential, Janus does not attempt to obfuscate simple operations with cognitively complex purely functional abstractions.

Of note should be the [Janus Standard Library](https://github.com/clint-tseng/janus-stdlib), which contains useful default implementations of core Janus components, and the [Janus Samples](https://github.com/clint-tseng/janus-samples) repository, which contains a growing library of illustrative Janus projects.

Janus is nearing API stabilization. Some minor calls are still shifting around, but at this point the big conceptual changes are over with and new versions should necessitate only minor find-and-replace operations. Please see the below roadmap for further details. Authors are still cautioned to avoid using Collection folds until the completion of `0.4`.

[![Build Status](https://img.shields.io/travis/clint-tseng/janus.svg)](http://travis-ci.org/clint-tseng/janus) [![NPM version](https://img.shields.io/npm/v/janus.svg)](https://www.npmjs.com/package/janus)

Overview
--------

Janus is comprised of some core abstractions that are independently useful, but then leveraged to form increasingly opinionated but powerful layers for constructing web applications:

* The **core library** contains basic building blocks:
    * **Varying** is the key abstraction and philosophical heart of Janus. Each **Varying** instance tracks a single current value, and manages the propagation of changes to that value to various downstream transformers and listeners. For both practical and mathematical reasons, it is Monad-compliant -- `get`, `map`, `flatten`, and `flatMap` are all provided, and the final result may be directly observed via `react` and `reactNow`.
    * The **case** system is an implementation of a typical functional case classing and matching system. Its purpose is to provide a formal construct through with acceptable value classes, their inner values, and matchers thereof may be communicated and implemented. In many cases, Janus framework components implement a default set of case classes that may be overridden or augmented with custom sets, allowing for great flexibility when the framework does not behave as needed out of the box.
    * **from** and its builder system sit on top of both `Varying` and `case` to provide a point-free way to declaratively define various necessary values and their combination into a final result, without specifically referencing object instances. This is used, for instance, in the templating engine to allow `Model` properties to be bound onto DOM objects declaratively and statelessly.
* The **templating system** provides structure and management implementation for databinding `Varying` values onto a DOM tree:
    * The **mutators** are concrete operations that map `Varying`-wrapped values onto DOM state in various ways: class names, textual contents, style properties, and wholesale rendering of subviews are accomplished through mutators. Each mutator declaration represents precisely one binding.
    * **Templates** group mutators together into view components. Traditionally, each template has a one-to-one relationship with the DOM fragment it manages. Effort is made to make templates easily composable, such that oft-reused sets of bindings may be easily recomposed, without complicated inheritance trees to manage.
* The **view system** has at its core the `DomView`, which wraps and manages the lifecycle of templates and their associated DOM fragments, as well as their binding to a `Model` object. The more-generic `View` sheds any DOM-based assumptions, allowing for alternative view artifact types.
* **Collections** are a set of data structures that resemble a fairly standard collections library, but with a dedication to facilities that enable the use of `Varying` and functional approaches rather than imperative operations that are time-sensitive. For instance, given collection `a`, we can derive collection `b = a.map((x) -> x + 1)` as expected, but updates to collection `a` will be result in recalculation and update of collection `b`. The primary data structures are `Map` and `List`.
* **Models** are `Maps` augmented with sematic behaviours to resemble traditional model objects. As with collections, while a model object's properties may be trivially set imperatively with `#set(key, value)`, use of `#get(key)` is highly discouraged -- instead, `#watch(key)` is the standard practice, which returns a `Varying`. Models contain many useful mechanisms for declaring behaviour on particular properties, such as serialization strategies or validation conditions.
* The remaining components in Janus fill in various gaps that manage application lifecycle at a broader level than the above systems, and tie the resulting application to its host framework.
    * To be written after reconsideration of `0.5`.

Philosophically, Janus hews closer to an MVVM approach than an MVC one -- any behaviour that doesn't comfortably fit into model or template declaration is likely accomplishable by inserting an intermediate `ViewModel` between the data Model and its template. Most controller-like behaviour are in practice very short, understandable snippets of imperative programming within `View`s.

Roadmap
-------

There remain three major blocs of work to be accomplished before a `1.x` release can be considered:

* `0.4` will be a refactoring of `Collection`:
    * For the most part, the external collection API is entirely satisfactory, in that it resembles a standard collection API. But it merits a revisit.
    * Everything is eagerly-evaluated, which simplifies a lot of operations, but probably shouldn't be the only option.
    * The various `fold`-related operations are nearly unusable at the moment.
    * Alternative approaches to our current system, possibly including a greater focus on lazy evaluation and/or transducers, will be evaluated.
    * `0.4` should be **almost entirely backward compatible**.
* `0.5` serves as a release candidate for all of the above changes, as well as an umbrella milestone for improvements, changes, or removals to the `application` package.
* `1.0` will follow, stabilizing the API for the first time.

Major Changelog
---------------

### [0.3](https://github.com/clint-tseng/janus/compare/0.2...0.3)

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


### [0.2](https://github.com/clint-tseng/janus/compare/0.1...0.2)

Completely overhauled and rewrote the `Varying` abstraction, as well as much of the templating, view, model, and collections systems that were too tightly-bound to `Varying` to escape rewrite. Introduced `case` and `from` as vital core abstractions. Also dramatically increased test coverage, streamlined and removed a bunch of fluff components, and other miscellenia.

* `Varying` became a true monad: it no longer automatically flattens its contents. It also no longer uses an event-based system for change propagation, as this resulted in intractable race condition problems as well as performance issues. Many improvements and changes aren't listed here.
* The `case` system is new, and an attempt to formalize and abstract the internal behaviour-handling models of Janus such that they can be easily augmented or replaced in userland where needed. It is a response to the problems with `instanceof`-based casing.
* The `from` system is a reconsideration of how databinding can be declared and executed. Its point-free programming model enables it to be freely leveraged to solve any number of problems unrelated to databinding.
* `Mutator` and `Template` are ground-up reconsiderations of how to bundle template-like behaviour.
* `View` and `Model` are impacted insofar as their interfaces to the above are concerned.
* Alongside this release is the new [`janus-stdlib`](https://github.com/clint-tseng/janus-stdlib), which contains a slew of very useful default View implementations for the objects in the library.

### 0.1

Initial release. All the basics are here, but given that the philosophy codified alongside the development, the exposed API is less than precise and often in conflict with the underlying machinations.

License
-------

Janus is licensed under the [WTFPL](http://www.wtfpl.net/about/).

