default: build

SRC = $(shell find src -name "*.coffee" -type f | sort)
LIB = $(SRC:src/%.coffee=lib/%.js)

lib:
	mkdir -p lib/

lib/inspect.css: src/inspect.sass lib
	node node_modules/node-sass/bin/node-sass --output-style compressed $< > $@

lib/%.js: src/%.coffee lib node_modules
	node node_modules/coffee-script/bin/coffee --output "$(@D)" --compile "$<"

node_modules:
	npm install

build: $(LIB) lib/inspect.css

test: build node_modules
	node node_modules/mocha/bin/mocha --require coffee-script/register test/**/*.coffee

test-coverage: build node_modules
	node node_modules/.bin/istanbul cover node_modules/.bin/_mocha -- --require coffee-script/register test/**/*.coffee

clean:
	rm -rf lib

