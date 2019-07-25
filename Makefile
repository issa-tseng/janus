.PHONY: build-all test-all
default: build-all

janus/node_modules:
	lerna bootstrap

build-all: janus/node_modules
	find . -type d -maxdepth 1 -not -name '.*' -print0 | xargs $(MAKE) -C

test-all: janus/node_modules
	node node_modules/mocha/bin/mocha --compilers coffee:coffeescript/register --recursive "*/test/**/*.*"

