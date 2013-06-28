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

Components
==========

To be rewritten, and to be completely reorganized.

    util = require('./util/util')

    janus =
      util: util # life-saving util funcs

      Model: require('./model/model').Model
      attribute: require('./model/attribute')
      store: require('./model/store')
      serializer: require('./model/serializer')

      collection: require('./collection/collection')

      View: require('./view/view').View
      DomView: require('./view/dom-view').DomView
      Templater: require('./templater/templater').Templater
      templater: require('./templater/package')

      Library: require('./library/library').Library
      varying: require('./core/varying')

      application:
        App: require('./application/app').App
        endpoint: require('./application/endpoint')
        handler: require('./application/handler')
        manifest: require('./application/manifest')

        PageModel: require('./model/page-model').PageModel
        PageView: require('./view/page-view').PageView

        ListView: require('./view/collection/list').ListView
        ListEditView: require('./view/collection/list-edit').ListEditView

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

