Janus
=====

Janus is a functional, reactive Javascript framework which makes complex user interfaces safe and easy to realize. Modular but opinionated, Janus is built on a strong formal base but provides powerful, familiar building blocks.

Built around functional ideals and concepts like declarative and reactive programming, immutability, and composability but with a dedication toward pragmatism, programmer-friendliness, and readable, ergonomic APIs, Janus is well-suited for projects small and large, simple and complex.

**Detailed documentation may be found at the [Janus website](http://janusjs.org).**

[![Build Status](https://img.shields.io/travis/issa-tseng/janus.svg)](http://travis-ci.org/issa-tseng/janus) [![NPM version](https://img.shields.io/npm/v/janus.svg)](https://www.npmjs.com/package/janus)

> **Hello Strange Loop viewers!**
>
> You might be wondering arriving here: what state is this project in? Should I use it? _What_ should I feel okay using it for? What help does the project need?
>
> Janus is young but the core is stable. I feel very confident about the basic functionality and use it often without much issue. That said, there are bugs and it does have its performance limitations, as discussed in the talk. If you don't mind reporting (and possibly helping with) the odd bug here and there, and you do some basic benchmarking against your needs, I think Janus is feasible for production development. It has certainly shipped in commercial/production products before, and those deployments have remained pretty resilient.
>
> If you are doing any UI prototyping or playing with things on your own, _absolutely give Janus a try_.
>
> Last, what help is Janus looking for? First and foremost, I think the above. Bang on it and let's smooth over some of the rough edges and bugs that get exposed through broader use. Next, ideas you have for making it more conducive to certain functional workflows, or for improving the performance, or anything else are very very welcome! I had a good idea going into Janus how I wanted it to _feel_ in use, and how familiar I wanted the syntax to look to web developers working today. What I never had and still don't today are deep experience with DOM performance quirks, and deep knowledge of functional and FRP methods. Janus could really use your experiences!
>
> _(PS: The Apollo site I mention is [here](http://apollo13realtime.org).)_

Basic Usage
-----------

Janus is distributed exclusively over [npm](https://www.npmjs.com/package/janus). To use it, include `janus` in your `package.json` file, and begin pulling tools out of the package as you see fit. You can find the latest version information above, and at the top of the documentation website.

If you're still looking for more information, you probably want to read the [Getting Started](http://janusjs.org/intro/getting-started) guide.

Monorepository
--------------

Janus uses a [Lerna monorepo](https://lerna.js.org) model for managing its core packages. This makes it easier to manage changes across the different packages, and to maintain integration tests that ensure they work well together. The Development section below describes how this works.

The core Janus package is located under [`janus/`](https://github.com/issa-tseng/janus/tree/master/janus). It contains the foundational abstractions, data structures, view and templating systems, and the application packages that form a complete but minimal frontend application framework.

Most projects will rely on the standard library, found under [`stdlib/`](https://github.com/issa-tseng/janus/tree/master/stdlib), which contains useful default view implementations of core Janus components such as lists and textboxes, as well as many handy ways to manipulate Varying values.

Here as well is Inspect, which provides tools and views that can be used to introspect into Janus internals. They are immensely useful for development and debugging, and are the primary workhorses behind the interactive sample and console on the Janus website, as well as Janus Studio. You can find them under [`inspect/`](https://github.com/issa-tseng/janus/tree/master/inspect).

Other Repositories
------------------

The documentation website source may be found at [`janus-docs`](https://github.com/issa-tseng/janus-docs). In addition to the markdown text content of the site and its static-site framework, the docs repository also contains the control flow backing the interactive samples and REPL console.

As well, the [`janus-samples`](https://github.com/issa-tseng/janus-samples) repository contains some illustrative Janus projects, for those who learn best by staring directly at code.

Development
-----------

To get started working on Janus code, you'll first need Node 0.10+ and npm. We use `make` to handle all our builds: `make build-all` will bootstrap the repository for you (installing dependencies and running `lerna bootstrap` to cross-link the development packages with each other), and rebuild each of the packages. If you run into trouble here, try rerunning `lerna bootstrap` or `lerna link` directly.

You can use `make test-all` to run all the tests across all packages at once, with a single result report.

You can also work on each package individually; once you `cd` into a package directory a separate `Makefile` will be present which will typically allow you to `make` just the files in that repository, `make test` just those tests, or `make test-coverage` to get a coverage report.

Future and Roadmap
------------------

Janus is relatively mature and nearing API stabilization. Some minor calls are still shifting around, but at this point the big conceptual changes are over with and new versions should necessitate only minor find-and-replace operations. With the release of 0.5, there remains only one major problem to be solved before a `1.x` release can be considered:

* `0.6` will be a refactoring of `Collection`:
    * For the most part, the external collection API is entirely satisfactory, in that it resembles a standard collection API. But it merits a revisit.
    * Everything is eagerly-evaluated, which simplifies a lot of operations, but probably shouldn't be the only option, or possibly even the default.
    * Some `fold`-related operations are nearly unusable at the moment, performance-wise.
    * Resource management is tricky because every chained invocation produces an eager object that must be manually deallocated.
    * Alternative approaches to our current system, possibly including a greater focus on lazy evaluation and/or transducers, will be evaluated.
    * The use of such a lazy transducer system in a more-performant render system will be considered.
    * `0.6` should be **almost entirely backward compatible**.
* `1.0` will follow, stabilizing the API for the first time.

Until version 0.6, authors should be cautious about the fold operations, especially `.join`, `.foldl`, and `.scanl` for moderate-to-large lists, for performance reasons.

A detailed changelog for previous releases may be found [here](https://github.com/issa-tseng/janus/blob/master/CHANGELOG.md).

Community and Contributing
--------------------------

Community resources are still being created. We do have a [Code of Conduct](http://janusjs.org/community/code-of-conduct) that we take very seriously.

Issue tickets and pull requests are extremely welcome.

Should you make contributions to this project, you agree to have your contributions licensed as described below.

License
-------

Janus is dual-licensed under the [WTFPL](http://www.wtfpl.net/about/) and the [BSD Zero Clause License](https://spdx.org/licenses/0BSD.html).

