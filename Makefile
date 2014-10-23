export PATH := node_modules/.bin:${PATH}

VERSION=$(shell node -e 'console.log(require("./package.json")["version"])')


.PHONY: dist
dist: worker.js runner.js


%.js: src/%.coffee
	coffee --compile --print $< > $@
	git add $@



.PHONY: test publish precommit
test: dist
	mocha test

publish: test assert-clean-tree assert-proper-version
	git tag "v${VERSION}"
	git push
	npm publish

precommit: dist



.PHONY: assert-clean-tree
assert-clean-tree:
	@(git diff --exit-code --no-patch \
    && git diff --cached --exit-code --no-patch) \
		|| (echo "There are uncommited files" && false)

.PHONY: assert-proper-version
assert-proper-version:
	@if echo "${VERSION}" | grep --quiet '.*-dev'; \
	 then echo "Found development version" && false; fi
