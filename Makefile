VERSION = 0.0.1

.PHONY: build
build: 
	swift build

# --parallel
.PHONY: test
test: build
	@swift test -v 2>&1 | xcpretty

.PHONY: release
release: 
	@swift build -c release

.PHONY: install
install: release
	@cp .build/release/leakDetect /usr/local/bin

.PHONY: clear
clear: 
	@rm /usr/local/bin/leakDetect

.PHONY: clearAll
clearAll: clear
	@rm -Rf .build

.PHONY: libs
libs: release
	otool -L .build/release/leakDetect

.PHONY: libDetail
libDetail: release
	otool -l .build/release/leakDetect

.PHONY: graph
graph:
	swift package show-dependencies --format dot | dot -Tsvg -o graph.svg
