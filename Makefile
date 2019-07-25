.PHONY: build-all test-all
default: build-all

node_modules:
	npm install

janus/node_modules: node_modules
	lerna bootstrap

build-all: janus/node_modules
	find . -type d -maxdepth 1 -not -name '.*' -print0 | xargs $(MAKE) -C

test-all: node_modules janus/node_modules
	node node_modules/mocha/bin/mocha --compilers coffee:coffeescript/register --recursive "*/test/**/*.*"

