PYTHON_DATA_DIR = ../syllabreak-python/syllabreak/data
SWIFT_RESOURCES_DIR = Sources/Syllabreak/Resources

.PHONY: build test lint clean install convert-yaml

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

convert-yaml:
	python3 -c "import yaml, json; json.dump(yaml.safe_load(open('$(PYTHON_DATA_DIR)/rules.yaml')), open('$(SWIFT_RESOURCES_DIR)/rules.json', 'w'), indent=2)"
	python3 -c "import yaml, json; json.dump(yaml.safe_load(open('$(PYTHON_DATA_DIR)/syllabify_tests.yaml')), open('$(SWIFT_RESOURCES_DIR)/syllabify_tests.json', 'w'), indent=2)"
	python3 -c "import yaml, json; json.dump(yaml.safe_load(open('$(PYTHON_DATA_DIR)/detect_language_tests.yaml')), open('$(SWIFT_RESOURCES_DIR)/detect_language_tests.json', 'w'), indent=2)"