Janus
=====

Janus is a functional, reactive Javascript framework which makes complex user interfaces safe and easy to realize. Modular but opinionated, Janus is built on a strong formal base but provides powerful, familiar building blocks.

Built around functional ideals and concepts like declarative and reactive programming, immutability, and composability but with a dedication toward pragmatism, programmer-friendliness, and readable, ergonomic APIs, Janus is well-suited for projects small and large, simple and complex.

**Detailed documentation may be found at the [Janus website](http://janusjs.org).**

[![Build Status](https://img.shields.io/travis/issa-tseng/janus.svg)](http://travis-ci.org/issa-tseng/janus) [![NPM version](https://img.shields.io/npm/v/janus.svg)](https://www.npmjs.com/package/janus)

Basic Usage
-----------

Janus is distributed exclusively over [npm](https://www.npmjs.com/package/janus). To use it, include `janus` in your `package.json` file, and begin pulling tools out of the package as you see fit. You can find the latest version information above, and at the top of the documentation website.

If you're still looking for more information, you probably want to read the [Getting Started](http://janusjs.org/intro/getting-started) guide.

Compiling
---------

You must have NodeJS 0.10+, and some relatively reasonable version of `npm`. We use `make`; all you should have to do is run `make` and everything should build. `make test` runs the tests; `make test-coverage` will give you a coverage report.

Repositories
------------

This repository contains all of core Janus: the main abstractions and data structures, the view and templating system, and the application packages tying everything together.

Most projects will rely on the [`janus-stdlib`](https://github.com/issa-tseng/janus-stdlib), which contains useful default view implementations of core Janus components such as Lists and textboxes, as well as many useful ways to manipulate Varying values.

The documentation website source may be found at [`janus-docs`](https://github.com/issa-tseng/janus-docs). In addition to the markdown text content of the site and its static-site framework, the docs repository also contains all the code relevant to presenting the interactive samples and REPL console.

However, the core tools and views used by those samples and REPL to inspect into Janus internals may be found at [`janus-inspect`](https://github.com/issa-tseng/janus-inspect).

Finally, the [`janus-samples`](https://github.com/issa-tseng/janus-samples) repository contains some illustrative Janus projects, for those who learn best by staring directly at code.

Future and Roadmap
------------------

Janus is relatively mature and nearing API stabilization. Some minor calls are still shifting around, but at this point the big conceptual changes are over with and new versions should necessitate only minor find-and-replace operations. With the release of 0.5, there remains only one major problem to be solved before a `1.x` release can be considered:

* `0.6` will be a refactoring of `Collection`:
    * For the most part, the external collection API is entirely satisfactory, in that it resembles a standard collection API. But it merits a revisit.
    * Everything is eagerly-evaluated, which simplifies a lot of operations, but probably shouldn't be the only option.
    * Some `fold`-related operations are nearly unusable at the moment, performance-wise.
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

Janus is dual-licensed under the [WTFPL](http://www.wtfpl.net/about/) and the [BSD Zero Clause License](https://spdx.org/licenses/0BSD.html), the latter really being offered only for the sake of organizations for which respectability is a major concern.

