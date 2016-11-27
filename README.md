Janus
=====

Janus is a library-framework designed to simplify web application flow through the application of FRP and reactive programming principles. It was conceived in order to facilitate applications that could be freely rendered server- and client-side from a single codebase -- the dedication to purely functional userland code and idempotent rendering/templating operations arose as a natural outcome of this goal. This is not a complete application framework -- it contains many of the relevant building blocks, but needs to be supplemented with, amongst other things, a DOM manipulation library like jQuery, and a web application server like Express or Flatiron.

Janus is different from other FRP frameworks in two predominant ways: it is meant to look familiar and friendly to application programmers with a background writing traditional Javascript web applications, and it eschews any desire to model streams of events and signals over time, instead concentrating on providing easy, stateless mappings from the current state of the system to the UI. It does so through pragmatic purity -- in cases where imperative code can be made perfectly clear and side effects are inconsequential, Janus does not attempt to obfuscate simple operations with cognitively complex purely functional abstractions.

Janus is current undergoing significant refitting. I would discourage any adoption prior to the release of version 0.2 at least.

[![Build Status](https://secure.travis-ci.org/clint-tseng/janus.png)](http://travis-ci.org/clint-tseng/janus)

Overview
--------

Janus is comprised of some core abstractions that are independently useful, but then leveraged to form increasingly opinionated but powerful layers for constructing web applications:

* The **core library** contains basic building blocks:
    * **Varying** is the key abstraction and philosophical heart of Janus. Each **Varying** instance tracks a single current value, and manages the propagation of changes to that value to various downstream transformers and listeners. For both practical and mathematical reasons, it is Monad-compliant -- `get`, `map`, `flatten`, and `flatMap` are all provided, and the final result may be directly observed via `react` and `reactNow`.
    * The **case** system is an implementation of a Scala-style case classing system. Its purpose is to provide a formal construct through with acceptable value classes, their inner values, and matchers thereof may be communicated and implemented. In many cases, Janus framework components implement a default set of case classes that may be overridden or augmented with custom sets, allowing for great flexibility when the framework does not behave as needed out of the box.
    * **from** and its builder system sit on top of both `Varying` and `case` to provide a point-free way to declaratively define various necessary values and their combination into a final result, without specifically referencing object instances. This is used, for instance, in the templating engine to allow `Model` properties to be bound onto DOM objects declaratively and statelessly.
* The **templating system** provides structure and management implementation for databinding `Varying` values onto a DOM tree:
    * The **mutators** are concrete operations that map `Varying`-wrapped values onto DOM state in various ways: class names, textual contents, style properties, and wholesale rendering of subviews are accomplished through mutators. Each mutator declaration represents precisely one binding.
    * **Templates** group mutators together into view components. Traditionally, each template has a one-to-one relationship with the DOM fragment it manages. Effort is made to make templates easily composable, such that oft-reused sets of bindings may be easily recomposed, without complicated inheritance trees to manage.
* The **view system** has at its core the `View`, which wraps and manages the lifecycle of templates and their associated DOM fragments, as well as their binding to a `Model` object. It also contains a small handful of useful default view implementations, primarily for handling collections.
* **Models** are bundles of `Varying`s into useful object abstractions resembling traditional model objects. The primary difference is that while an object's properties may be trivially set imperatively with `#set(key, value)`, use of `#get(key)` is highly discouraged -- instead, `#listen(key)` is the standard practice, which returns a `Varying`. Models also contain many useful mechanisms for declaring behaviour on particular properties, such as serialization strategies or validation conditions. **Model is due for a major overhaul in version 0.3.**
* **Collections** are similar to models in that they resemble a fairly standard collections library, but with a dedication to facilities that enable the use of `Varying` and functional approaches rather than imperative operations. For instances, given collection `a`, we can derive collection `b = a.map((x) -> x + 1)` as expected, but updates to collection `a` will be result in recalculation and update of collection `b`. **Collection is due for a major overhaul in version 0.4**.
* The remaining components in Janus fill in various gaps that manage application lifecycle at a broader level than the above systems, and tie the resulting application to its parent host framework.
    * To be written after reconsideration of `0.5`.

Philosophically, Janus hews closer to an MVVM approach than an MVC one -- any behaviour that doesn't comfortably fit into model or template declaration is likely accomplishable by inserting an intermediate `ViewModel` between the data Model and its template. Most controller-like behaviour is in practice very short, understandable bursts of imperative programming within `View`s.

Roadmap
-------

Currently, the `0.1` branch of Janus is fully functional and comprehensive, but after two years of using and deploying it in various systems, better approaches have become clear that I'd like to apply before any 1.x release:

* `0.2` represents a complete overhaul and rewrite of the `Varying` abstraction, as well as some of the templating and view systems that are too tightly-bound to `Varying` to escape rewrite:
    * `Varying` becomes a true monad, and no longer uses an event-based system for change propagation, as this resulted in intractable race condition problems as well as performance issues. Many improvements and changes aren't listed here.
    * The `case` system is new, and an attempt to formalize and abstract the internal behaviour-handling models of Janus such that they can be easily augmented or replaced in userland where needed. It exists as a full system due to the need to counter `npm` behaviour.
    * The `from` system is a reconsideration of how databinding can be declared and executed. Its point-free programming model enables it to be freely leveraged to solve any number of problems unrelated to databinding.
    * `Mutator` and `Template` are ground-up reconsiderations of how to bundle template-like behaviour.
    * `View` and `Model` are impacted insofar as their interfaces to the above are concerned.
    * `0.2` is strictly **not backwards compatible**, as it represents a major formalization effort that can impact the behaviour of code that was loose but would function in `0.1`.
* `0.3` will be the great unbundling of `Model`:
    * The meanest, smallest kernel of the model system will become the `Struct`, which is purely a collection of `Varying` objects addressed by property keys.
    * All follow-on behaviour that `Model` currently supports become either increasingly powerful subclasses, or extension behaviour that may be plugged in to `Model`: shadow copying, attribute behaviour, property binding, validation, serialization, and change tracking.
    * Enumerability (hashes whose k/v pairs may be mapped) likely goes here, possibly to support serialization and change tracking.
    * Serialization/change tracking mechanisms for collections will also be considered in this rev; no tests will be written for either in the meantime.
    * `0.3` will required **minor code changes** -- all the final features are superset and all concepts remain identical, but things will be cleaned up internally and possibly minorly moved about.
* `0.4` will be a refactoring of `Collection`:
    * For the most part, the external collection API is entirely satisfactory, in that it resembles a standard collection API. But the internal code is a bit slipshod.
    * In particular, memory efficiency and performance are not strong suits.
    * And in particular within that, the various `fold`-related operations are nearly unusable at the moment.
    * Alternative approaches to our current system, possibly including a greater focus on lazy evaluation and/or transducers, will be evaluated.
    * As above-hinted, 0.4 should remain **almost entirely backward compatible**.
* `0.5` serves as a release candidate for all of the above changes, as well as an umbrella milestone for improvements, changes, or removals to application-level code.
* `1.0` will follow, stabilizing the API for the first time.

License
-------

Janus is licensed under the [WTFPL](http://www.wtfpl.net/about/).

