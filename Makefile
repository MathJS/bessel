LIB=bessel
REQS=
ADDONS=
AUXTARGETS=
HTMLLINT=index.html

ULIB=$(shell echo $(LIB) | tr a-z A-Z)
DEPS=$(sort $(wildcard bits/*.js))
TARGET=$(LIB).js
FLOWTARGET=$(LIB).flow.js

## Main Targets

.PHONY: all
all: $(TARGET) $(AUXTARGETS) ## Build library and auxiliary scripts

$(TARGET) $(AUXTARGETS): %.js : %.flow.js
	node -e 'process.stdout.write(require("fs").readFileSync("$<","utf8").replace(/^[ \t]*\/\*[:#][^*]*\*\/\s*(\n)?/gm,"").replace(/\/\*[:#][^*]*\*\//gm,""))' > $@

$(FLOWTARGET): $(DEPS)
	cat $^ | tr -d '\15\32' > $@

bits/01_version.js: package.json
	echo "BESSEL.version = '"`grep version package.json | awk '{gsub(/[^0-9a-z\.-]/,"",$$2); print $$2}'`"';" > $@

.PHONY: clean
clean: ## Remove targets and build artifacts
	rm -f $(TARGET) $(FLOWTARGET)

## Testing

.PHONY: test mocha
test mocha: test.js $(TARGET) ## Run test suite
	mocha -R spec -t 20000

.PHONY: ctest
ctest: ## Build browser test (into ctest/ subdirectory)
	cp -f test.js ctest/test.js
	cp -f shim.js ctest/shim.js
	cp -f $(TARGET) ctest/

.PHONY: ctestserv
ctestserv: ## Start a test server on port 8000
	@cd ctest && python -mSimpleHTTPServer


## Code Checking

.PHONY: lint
lint: $(TARGET) $(AUXTARGETS) ## Run jshint and jscs checks
	@jshint --show-non-errors $(TARGET) $(AUXTARGETS)
	@jshint --show-non-errors package.json
	@jshint --show-non-errors --extract=always $(HTMLLINT)
	@jscs $(TARGET) $(AUXTARGETS)

.PHONY: flow
flow: lint ## Run flow checker
	@flow check --all --show-all-errors

.PHONY: cov
cov: misc/coverage.html ## Run coverage test

misc/coverage.html: $(TARGET) test.js
	mocha --require blanket -R html-cov -t 20000 > $@

.PHONY: coveralls
coveralls: ## Coverage Test + Send to coveralls.io
	mocha --require blanket --reporter mocha-lcov-reporter -t 20000 | node ./node_modules/coveralls/bin/coveralls.js


.PHONY: help
help:
	@grep -hE '(^[a-zA-Z_-][ a-zA-Z_-]*:.*?|^#[#*])' $(MAKEFILE_LIST) | bash misc/help.sh

#* To show a spinner, append "-spin" to any target e.g. cov-spin
%-spin:
	@make $* & bash misc/spin.sh $$!
