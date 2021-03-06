Janus Standard Library
======================

The Janus Standard Library is a collection of useful `View`s and `Varying` helpers that reflect one opinionated way of building an application on top of [Janus](https://github.com/issa-tseng/janus). Probably the most useful thing it does is provide generic, generally applicable default views for all the default `Attribute` class types, as well as `List`, in both `default` and `edit` contexts.

It depends on the presence of a DOM manipulation library largely compatible with the jQuery API: jQuery, Zepto, (and Cheerio? [TBD]) are all supported targets.

[![Build Status](https://img.shields.io/travis/issa-tseng/janus-stdlib.svg)](http://travis-ci.org/issa-tseng/janus-stdlib) [![NPM version](https://img.shields.io/npm/v/janus-stdlib.svg)](https://www.npmjs.com/package/janus-stdlib)

Usage
-----

To start, require the npm package: `janus-stdlib`.

You can register the entire library wholesale (recommended): `require('janus-stdlib').view.registerWith(myLibrary)`.

Or, you can pick and choose what you wish to register; for instance: `view.registerWith(myLibrary) for view in require('janus-stdlib').view when view not in [ 'literal', 'varying' ]`.

As noted above, there needs to be a jQuery-compatible library available. Currently, we default to using a combination of [`domino`](https://github.com/fgnass/domino) and [`jQuery`](https://github.com/jquery/jquery) for server-side rendering and unit testing (this may be replaced by [`Cheerio`](https://cheerio.js.org/) at some point in the future), and we require [a local reference to `janus-dollar`](http://janusjs.org/further-reading/dollar) to understand which DOM manipulation library you are using.

Development
-----------

Should be standard and straightforward: clone the repository, and `make` should set everything up assuming you have `npm` and `node` installed already. You can also `make test` to run the unit tests, or `make test-coverage` to run the unit tests and generate a code coverage report.

Contributing
------------

Pull requests are welcome. If you wish to contribute, please bear in mind:

* This is meant to be a relatively opinion-free standard library. Functionality that is too specific or pulls in particular dependencies are likely to be rejected.
* Please do run the unit tests (`make test`) and create new ones where relevant.
* Remember to write code in the philosophy of Janus. Avoid mutable state wherever possible, and leverage the `Varying` monad for as much business logic and state management as you can.

License
-------

The Janus Standard Library is licensed under the [WTFPL](http://www.wtfpl.net/about/).

