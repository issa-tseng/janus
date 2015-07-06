Janus
=====

Janus is a lightweight library-framework that is designed to be just large
enough to express an opinion about application organization and provide the
general abstractions and standard library to support that opinion. It is not an
application framework -- in fact, its default assumption is that one will use
the excellent [Flatiron.js](http://flatironjs.org/) framework for actually
building a webserver and webapp. It seeks to establish a discipline about the
management of system state through ideas derived from FRP and reactive
programming.

[![Build Status](https://secure.travis-ci.org/clint-tseng/janus.png)](http://travis-ci.org/clint-tseng/janus)

Overview
========

Being rewritten!

Components
==========

To be rewritten, and to be completely reorganized.

    util = require('./util/util')

    janus = (window ? global)._janus$ ?=
      util: util # life-saving util funcs

      Base: require('./core/base').Base

      Model: require('./model/model').Model
      reference: require('./model/reference')
      attribute: require('./model/attribute')
      Issue: require('./model/issue').Issue
      store: require('./model/store')

      collection: require('./collection/collection')

      View: require('./view/view').View
      DomView: require('./view/dom-view').DomView
      Templater: require('./templater/templater').Templater
      templater: require('./templater/package')

      Library: require('./library/library').Library
      varying: require('./core/varying')
      Chainer: require('./core/chain').Chainer

      application:
        App: require('./application/app').App
        endpoint: require('./application/endpoint')
        handler: require('./application/handler')
        manifest: require('./application/manifest')

        PageModel: require('./model/page-model').PageModel
        PageView: require('./view/page-view').PageView

        VaryingView: require('./view/impl/varying').VaryingView
        ListView: require('./view/impl/list').ListView
        listEdit: require('./view/impl/list-edit')

Module
======

    util.extend(module.exports, janus)

The Janus package exports itself via a simple CommonJS drop of its core
components in an object. If you would like to support other loaders, please
submit them as a pull request and justify why they make sense for Janus.

Installation
============

Simply install with `npm`: `npm install janus`

Linting
=======

To install `coffeelint`, run:

```
npm i -g coffeelint
```

To run `coffeelint` in the `src` directory, run:

```
coffeelint src
```

See `package.json` for the configuration options.

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

