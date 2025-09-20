PYTHON_DATA_DIR = ../syllabreak-python/syllabreak/data
SWIFT_RESOURCES_DIR = Sources/Syllabreak/Resources
SWIFT_TEST_RESOURCES_DIR = Tests/SyllabreakTests/Resources

.PHONY: build test lint clean install convert-yaml

build:
	swift build

test:
	swift test

lint:
	swiftlint

lint-fix:
	swiftlint --fix

clean:
	swift package clean
	rm -rf .build Package.resolved

install:
	brew install swiftlint

sync-yaml:
	cp $(PYTHON_DATA_DIR)/rules.yaml $(SWIFT_RESOURCES_DIR)/
	cp $(PYTHON_DATA_DIR)/syllabify_tests.yaml $(SWIFT_TEST_RESOURCES_DIR)/
	cp $(PYTHON_DATA_DIR)/detect_language_tests.yaml $(SWIFT_TEST_RESOURCES_DIR)/