Janus
=====

Janus is a lightweight library-framework that is designed to be just large
enough to express an opinion about application organization and provide the
general abstractions and standard library to support that opinion. It is not an
application framework -- in fact, its default assumption is that one will use
the excellent [Flatiron.js](http://flatironjs.org/) framework for actually
building a webserver and webapp. It looks to [Backbone](http://backbonejs.org/)
for guidance on what best practices are at a general level, while seeking to
build upon its opinions.

[![Build Status](https://secure.travis-ci.org/clint-tseng/janus.png)](http://travis-ci.org/clint-tseng/janus)

Reference
=========

This documentation (which is actually the main Janus file!), along with all
other documentation, is available as [annotated
source](https://rawgithub.com/clint-tseng/janus/master/docs/janus.coffee.html).

Why Janus?
==========

There are many very popular frameworks out there to help build the kind of
gigantic, client-side-heavy, modern application that the web is moving towards.
A lot of them focus very heavily on slick server model bindings, fancy
templating, and features like component libraries with responsive design and
mobile support built in. However, these practices, while fantastic, don't work
for those of us who have to build SEO-friendly or [Section
508](http://en.wikipedia.org/wiki/Section_508_Amendment_to_the_Rehabilitation_Act_of_1973)-compliant
web applications.

Much like Backbone, Janus doesn't aim to answer a lot of questions. In
particular, it provides no native implementations or opinions on:

* Databases, backends, or ORM
* Web server
* Middleware
* Session storage
* URL Routing
* Network transport
* Standard controls

Instead, Janus focuses on organizing application code in a succinct,
maintainable way that encourages composition of behavior and code, modularity,
and reuse while providing better functionality around server-side rendering,
state representation across reload or navigation, and live data representation.
Where Backbone is unopinionated in the extreme to be able to fit any model,
Janus is opinionated where it suits its mission. It prevents bloat by
maintaining a very small footprint.

Philosophy
==========

Janus is, at its heart, an MVVM framework. More on this later. It has a number
of tenets that guide its design:

* Be as small and modular as possible.
* Be opinionated where it would help the core mission.
* Be automatic, but not automagic.
* Boilerplate isn't bad as long as it's small.
* Address different execution contexts -- server- and client- side.
* Encourage unit testing, and in fact make unit testing the obvious answer.
* Look to Backbone for guidance, and diverge only where it better suits the
  above.

Core Components
===============

Janus is comprised of a five major components, and a number of smaller but
critical utilities that help organize and connect the components together.

    util = require('./util/util')

    janus =
      util: util # life-saving util funcs

Model
-----

      Model: require('./model/model').Model

Janus models are extremely similar to Backbone models in many ways: they store
and event on a set of attributes. When one wants to refer to an entity concept
in a Janus application, they refer to its model class.

Unlike a Backbone model, a Janus model does not know how to serialize itself or
synchronize with a server. This functionality is provided through helper
classes -- one can request a serializer or synchronizer for a given model and
execution context.

Also unlike a Backbone model, attributes can be defined through a schema. This
allows some advantages:

* Knowledge of how to correctly parse data for the attribute, and knowledge of
  nested models.
* Validation can be expressed, where appropriate, per-attribute. This allows
  easier eventual rendering against a view.

Finally, Janus models provide multiple instances of their attributes. There is
always one canonical state, while the rest are exposed as overlays above it.
This allows for easier implementation of behaviors such as revert, diff, and
fork of model state without requiring multiple instances of a model.

Collection
----------

      Collection: require('./model/collection').Collection

Backbone doesn't provide much definition or guidance on what collections are
meant to represent -- they are quite simply useful wrappers around arrays of
models that provide some nice automation and default behavior. In reality, there
are two common types of scenarios where an array of models makes sense:

1. **Model-like Collections**: These are cases where the collection is likely to
   be wholly fetched, and dealt with as a single entity, because the collection
   itself is of model importance. Features that are likely to matter in these
   cases include: **collection ordering**, **model membership**, and
   **collection persistence**.
2. **View-like Collections**: These are cases where the actual contents of the
   collection at any given time are unlikely to be semantically significant. The
   exposed members are the result of pagination, filtering, or sorting on a
   larger collection, probably residing on the server. Likely to matter here are
   **collection attributes** and **attribute binding to a query**, **fetch and
   refresh of collection subsets**, and **result caching**.

These distinctions are useful to draw and provide good default behavior beyond
the basic array abstraction, but this does not mean the base abstraction is
useless -- it's a very functional strict mutual subset. Thus, it is still
provided as the core default -- the other behaviors are brought in as composed
behavior.

View
----

      View: require('./view/view').View
      DomView: require('./view/dom-view').DomView

Janus's opinions on views differ greatly from Backbone's. While it doesn't try
to impose a particular templating framework upon the developer either (though
one is provided as part of the framework), it does presume much more about how
maintainable code should be built.

In conjuction with Libraries (described below), Janus seeks to provide a method
through which application interfaces can be built as a series of loosely
connected components which expose the state of their underlying models in
different ways, and which are bound directly to the model's and the page's
states.

Janus does away with the automatic root node generation and event binding that
Backbone provides -- Views need not have anything to do with HTML. This minor
piece of opinion doesn't really serve to reduce any code duplication or
developer error anyway. Instead, all event binding occurs in a `bindEvents`
method -- we don't call this method in server contexts, and we can defer calls
to it client-side until they become necessary to save on-load execution time.

Each Janus view is only ever allowed to return one artifact, and it is
permanently bound to that artifact. This will usually be a DOM node, possibly
wrapped with jQuery or some other library object of choice. Calling `render()`
is thus a safe way to always retrieve the canonical manifestation of a view.

Views provide a rebinding facility to aid with cross-environment rendering. If
markup is generated on the server, the same model should be able to pick up and
use that markup without rerendering it. Thus, when the client-side view model
initializes, it calls `rebind` on the view tree. There is no default
implementation directly on the base view, but the templater provides one if you
are using it.

Templater
---------

      Templater: require('./templater/templater').Templater

The templater is the single most opinionated part of Janus. Its use is entirely
optional, but it also is the unifying element that brings a lot of the ideas and
default behavior into concrete reality.

In service of the other concepts in this framework, it is best not to allow the
DOM to implictly encode a different representation of model state. Dynamic
binding of model state to DOM state is a powerful concept when used correctly,
and it leads Janus to use declarative rather than string+syntax templating.

The templater works based on a DocumentFragment, a binding schema generator, and
one or more pieces of data. A default DocumentFragment loader is supplied that
works from string or from file.

The actual templating occurs in two parts -- first, the binding generator is
called, and given the data context. Once this returns, the actual binding
occurs. The staging is done via a call rather than via static data so that one
can work againts real objects rather than strings pointing at objects, and so
that more complex structures can be built where necessary. A full set of
bindings can be found in the reference, but the key features include:

* Takes `Value` objects that event on state change, and re-executes the binding
  on such occasions. Janus models provide a value generator per attribute.
* Allows additive logic on later-rebound instances of the same binding. This
  allows for views to be composed together and overridden without entirely
  clobbering existing bindings.
* Custom node manipulation via passed function. Use this sparingly!
* Easy, automatic fetch and call of Views for nested objects. Specific
  parameters can be provided for the fetched subview to cascade properties and
  state down.
* XSS protection by default.

Library
-------

      Library: require('./library/library').Library

The library is a facility that manage application components. Once a library
instance is created, objects can be registered against it. Registration involves
providing an object class or instance, and specifying what that object is used
for; objects can be registered against classes, a context string, a basic
descriptor hash, and if necessary a matcher function that returns a boolean.

Later, then, one can fetch a library component via a simple call to `get` with a
target object and some basic description. The library can do some predefined
work against the registered object, after which the result is returned for use.
This makes it very easy to build and fetch components against model objects.


      monitor: require('./core/monitor')

Standard Library
================

The Janus standard library provides a number of base classes that tie the core
components together into an MVVM framework that one can build web applications
against rather than just a basic collection of code-organization classes.

      application:

PageModel
---------

        PageModel: require('./model/page-model').PageModel

A `PageModel` is the concept that makes Janus an MVVM rather than MVC framework.
It is born out of the observation that controller methods on web applications
tend to fall into two general buckets: nonmutating endpoints that simply fetch a
bunch of information for render, or mutating endpoints that attempt an action,
then fall back on a nonmutating page with some preloaded state. The PageModel is
an attempt to encapsulate the common element of those requests with a single
object that is isomorphic with the concepts already offered by the framework.

PageModels are just like any other Janus model -- they get initialized with some
attributes, they can be rendered against with a view, and they provide eventing
when their attributes change.

In addition to the default behavior for a model, PageModels have by default a
`application` attribute bag. This bag is populated with application-state
attributes such as `GET` parameters, request information, session variables, and
such. Through the default attribute mechanism on models, of course, all of these
will event on change.

PageView
--------

        PageView: require('./view/page-view').PageView

The `PageView` is the view complement to the PageModel. It provides some basic
facilities like header/footer rendering, dropping in the Janus runtime, the
model state and page initialization.

Persister
---------

        Persister: require('./model/persister')

The `Persister` is nothing more than a implementationless base class that one
can use to guide building one's own persistence layer. It's recommended to
build a pair of base persisters that can be extended with model-specific
endpoints, and appropriate one per execution context.

Serializer
----------

        Serializer: require('./model/serializer')

The `Serializer` is a default implementation of serialization that takes models
and renders their attributes as JSON. There are hooks to provide custom behavior
for particular attributes (including nested model attributes), but by default it
handles all types and nested model serialization automatically.

CollectionView
--------------

        CollectionView: require('./view/collection')

The `CollectionView` is a DOM-rendering view that works against the base
collection class. It handles member insertion, removal, and reorder correctly,
and should be sufficient for most basic collection cases.

CollectionEditView
------------------

        CollectionEditView: require('./view/collection-edit')

The `CollectionEditView` extends the `CollectionView` with some basic controls
for adding and removing members. It's mostly provided as an example for how to
compose view behaviors together.

Module
======

    util.extend(module.exports, janus)

The Janus package exports itself via a simple CommonJS drop of its core
components in an object. If you would like to support other loaders, please
submit them as a pull request and justify why they make sense for Janus.

Installation
============

Simply install with `npm`: `npm install janus`

License
=======

Janus is licensed under the [WTFPL](http://www.wtfpl.net/about/):

    ###
            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                    Version 2, December 2004

    Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

    Everyone is permitted to copy and distribute verbatim or modified
    copies of this license document, and changing it is allowed as long
    as the name is changed.

               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
      TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

     0. You just DO WHAT THE FUCK YOU WANT TO.
    ###

