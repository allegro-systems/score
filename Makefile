SWIFT ?= swift
CONFIG ?= debug
WERROR ?= true
SWIFT_WERROR := $(if $(filter-out false,$(WERROR)),-Xswiftc -warnings-as-errors)
SHELL := /usr/bin/env bash

PRODUCT     ?= score
BINARY_PATH ?= bin
COVERAGE_MIN ?= 85
COVERAGE_ENFORCE_TARGETS ?= true

.DEFAULT_GOAL := help

.PHONY: help
help:
	@printf "%s\n" \
	"Targets:" \
	"  build          Build ($(CONFIG))" \
	"  release        Build in release mode" \
	"  test           Run tests ($(CONFIG))" \
	"  coverage       Run tests with coverage and enforce min $(COVERAGE_MIN)%" \
	"  ci             Run full local/CI gates" \
	"  ci-examples    Build all Examples/*/" \
	"  setup-hooks    Install pre-commit hook (runs make ci)" \
	"  format         Format (swift format)" \
	"  lint           Lint (swift format lint)" \
	"  install        Build release and install to BINARY_PATH (default: bin/)" \
	"  clean          Remove build artefacts"

.PHONY: build
build:
	@$(SWIFT) --version
	@$(SWIFT) build -c $(CONFIG) $(SWIFT_WERROR)

.PHONY: release
release:
	@$(MAKE) build CONFIG=release

.PHONY: test
test:
	@$(SWIFT) test -c $(CONFIG) $(SWIFT_WERROR)

.PHONY: coverage
coverage:
	@set -euo pipefail; \
	$(SWIFT) test -c $(CONFIG) $(SWIFT_WERROR) --enable-code-coverage; \
	CODECOV_PATH="$$( $(SWIFT) test -c $(CONFIG) --show-codecov-path )"; \
	echo "Coverage JSON: $$CODECOV_PATH"; \
	$(SWIFT) scripts/coverage.swift "$$CODECOV_PATH" "$(COVERAGE_MIN)" "$(COVERAGE_ENFORCE_TARGETS)" "$$(pwd)"

.PHONY: ci
ci:
	@$(MAKE) lint
	@$(MAKE) build WERROR=true
	@$(MAKE) coverage WERROR=true COVERAGE_MIN=$(COVERAGE_MIN) COVERAGE_ENFORCE_TARGETS=true
	@$(MAKE) ci-examples

EXAMPLES := $(wildcard Examples/*)

.PHONY: ci-examples
ci-examples:
	@set -euo pipefail; \
	for dir in $(EXAMPLES); do \
		echo "Building $$dir..."; \
		(cd "$$dir" && $(SWIFT) build -c $(CONFIG) $(SWIFT_WERROR)); \
	done; \
	echo "All examples built successfully."

.PHONY: setup-hooks
setup-hooks:
	@set -euo pipefail; \
	HOOK_PATH="$$(git rev-parse --git-path hooks/pre-commit)"; \
	printf '%s\n' \
	'#!/usr/bin/env sh' \
	'set -eu' \
	'ROOT="$$(git rev-parse --show-toplevel)"' \
	'cd "$$ROOT"' \
	'echo "[pre-commit] Running make ci..."' \
	'make ci' > "$$HOOK_PATH"; \
	chmod +x "$$HOOK_PATH"; \
	echo "Installed pre-commit hook at $$HOOK_PATH"

.PHONY: format
format:
	@$(SWIFT) format --recursive -i Sources Tests

.PHONY: lint
lint:
	@$(SWIFT) format lint --recursive --strict Sources Tests

.PHONY: install
install:
	@$(SWIFT) build -c release $(SWIFT_WERROR)
	@mkdir -p "$(BINARY_PATH)"
	@RELEASE_BIN=$$($(SWIFT) build -c release --show-bin-path) && \
	 install "$$RELEASE_BIN/$(PRODUCT)" "$(BINARY_PATH)/$(PRODUCT)" 2>/dev/null || \
	 (echo "note: product '$(PRODUCT)' not found. Set PRODUCT=<swiftpm product name>." && exit 1)

.PHONY: clean
clean:
	@rm -rf bin
	@$(SWIFT) package clean
