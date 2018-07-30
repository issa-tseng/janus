Janus
=====

Janus is a library-framework designed to simplify web application flow through the application of FRP and reactive programming principles. It was conceived in order to facilitate applications that could be freely rendered server- and client-side from a single codebase -- the dedication to purely functional userland code and idempotent rendering/templating operations arose as a natural outcome of this goal. This is not a complete application framework -- it contains many of the relevant building blocks, but needs to be supplemented with, amongst other things, a DOM manipulation library like jQuery or Zepto, and a web application server like Express.

Janus is different from other FRP frameworks in two predominant ways: it is meant to look familiar and friendly to application programmers with a background writing traditional Javascript web applications, and it eschews any desire to model streams of events and signals over time, instead concentrating on providing easy, stateless mappings from the current state of the system to the UI. It does so through pragmatic purity -- in cases where imperative code can be made perfectly clear and side effects are inconsequential, Janus does not attempt to obfuscate simple operations with cognitively complex purely functional abstractions.

Of note should be the [Janus Standard Library](https://github.com/clint-tseng/janus-stdlib), which contains useful default implementations of core Janus components, and the [Janus Samples](https://github.com/clint-tseng/janus-samples) repository, which contains a growing library of illustrative Janus projects.

Janus is relatively mature and nearing API stabilization. Some minor calls are still shifting around, but at this point the big conceptual changes are over with and new versions should necessitate only minor find-and-replace operations. Please see the below roadmap for further details. Authors are still cautioned to avoid using Collection folds until the completion of `0.6`.

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
* The **application package** contains three small but useful classes for tying everything together into a true client/server application, adding a component library and lifecycle management.

Philosophically, Janus hews closer to an MVVM approach than an MVC one -- any behaviour that doesn't comfortably fit into model or template declaration is likely accomplishable by inserting an intermediate `ViewModel` between the data Model and its template. Most controller-like behaviour are in practice very short, understandable snippets of imperative programming within `View`s.

Roadmap
-------

There remains only one major problem to be solved before a `1.x` release can be considered:

* `0.6` will be a refactoring of `Collection`:
    * For the most part, the external collection API is entirely satisfactory, in that it resembles a standard collection API. But it merits a revisit.
    * Everything is eagerly-evaluated, which simplifies a lot of operations, but probably shouldn't be the only option.
    * The various `fold`-related operations are nearly unusable at the moment, performance-wise.
    * Alternative approaches to our current system, possibly including a greater focus on lazy evaluation and/or transducers, will be evaluated.
    * The use of such a lazy transducer system in a more-performant render system will be considered.
    * `0.6` should be **almost entirely backward compatible**.
* `1.0` will follow, stabilizing the API for the first time.

License
-------

Janus is licensed under the [WTFPL](http://www.wtfpl.net/about/).

