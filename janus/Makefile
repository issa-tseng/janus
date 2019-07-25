default: build

SRC = $(shell find src -name "*.coffee" -type f | sort)
LIB = $(SRC:src/%.coffee=lib/%.js)

lib:
	mkdir -p lib/

lib/%.js: src/%.coffee lib node_modules
	node node_modules/coffee-script/bin/coffee --output "$(@D)" --compile "$<"

node_modules:
	npm install

build: $(LIB)

test: build node_modules
	node node_modules/mocha/bin/mocha --compilers coffee:coffee-script/register --recursive

test-debug: build node_modules
	node --debug-brk --inspect node_modules/mocha/bin/mocha --compilers coffee:coffee-script/register --recursive

test-coverage: build node_modules
	node node_modules/.bin/istanbul cover node_modules/.bin/_mocha -- --compilers coffee:coffee-script/register --recursive

clean:
	rm -rf lib

