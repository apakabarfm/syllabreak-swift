.PHONY: build test lint clean install

build:
	swift build

test:
	swift test

lint:
	swiftlint

clean:
	swift package clean

install:
	brew install swiftlint