Janus Core
==========

The Janus Core provides abstractions and utilities for constructing an interactive web application. This includes the core building blocks and data structures, the view and templating system, and the application packages tying everything together.

Development
-----------

You must have Node 0.10+, and some relatively reasonable version of `npm`. We use `make`; all you should have to do is run `make` and everything should build. `make test` runs the tests; `make test-coverage` will give you a coverage report.

There are some tests that will not run on versions of Node <6 as they exercise ES6 features that we offer. If you run into syntax errors in the tests, this is the likely problem. Comment out those tests and everything else should work just fine.

Contents
--------

A detailed walkthrough of the subdirectories here and their purposes may be found on the [Introduction page](http://janusjs.org/intro#component-walkthrough) on the Janus website.

