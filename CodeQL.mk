db:
	-rm -Rf swiftdb
	-rm -Rf .build
	swift package clean
	codeql database create \
		--language=swift \
		--source-root . \
		--search-path=/Users/yume/git/codeql/swift/extractor-pack \
		--command="swift build" \
		swiftdb

analyze:
	codeql database \
		analyze swiftdb \
		--format=sarifv2.1.0 \
		--output=out/xxx.sarif \
		/Users/yume/git/codeql/swift/ql/src/codeql-suites/swift-code-scanning.qls \
		/Users/yume/git/codeql/swift/ql/src/codeql-suites/swift-security-and-quality.qls \
		/Users/yume/git/codeql/swift/ql/src/codeql-suites/swift-security-extended.qls
