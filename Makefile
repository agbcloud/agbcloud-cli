# Build variables
BINARY_NAME=agb
VERSION?=dev
GIT_COMMIT?=$(shell git rev-parse --short HEAD)
BUILD_DATE?=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build flags
LDFLAGS=-ldflags "-X github.com/agbcloud/agbcloud-cli/cmd.Version=$(VERSION) -X github.com/agbcloud/agbcloud-cli/cmd.GitCommit=$(GIT_COMMIT) -X github.com/agbcloud/agbcloud-cli/cmd.BuildDate=$(BUILD_DATE)"

# Default target
.PHONY: all
all: build

# Build for current platform
.PHONY: build
build:
	go build $(LDFLAGS) -o bin/$(BINARY_NAME) .

# Build for all platforms
.PHONY: build-all
build-all: build-linux build-darwin build-windows

# Build Linux with maximum compatibility (static + older glibc target)
.PHONY: build-linux-compat
build-linux-compat:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -a -installsuffix cgo -tags netgo -ldflags '-extldflags "-static"' -o bin/$(BINARY_NAME)-linux-amd64-compat .
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build $(LDFLAGS) -a -installsuffix cgo -tags netgo -ldflags '-extldflags "-static"' -o bin/$(BINARY_NAME)-linux-arm64-compat .

# Build for Linux (static compilation for better compatibility)
.PHONY: build-linux
build-linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -a -installsuffix cgo -o bin/$(BINARY_NAME)-linux-amd64 .
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build $(LDFLAGS) -a -installsuffix cgo -o bin/$(BINARY_NAME)-linux-arm64 .

# Build for macOS
.PHONY: build-darwin
build-darwin:
	GOOS=darwin GOARCH=amd64 go build $(LDFLAGS) -o bin/$(BINARY_NAME)-darwin-amd64 .
	GOOS=darwin GOARCH=arm64 go build $(LDFLAGS) -o bin/$(BINARY_NAME)-darwin-arm64 .

# Build for Windows
.PHONY: build-windows
build-windows:
	GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o bin/$(BINARY_NAME)-windows-amd64.exe .
	GOOS=windows GOARCH=arm64 go build $(LDFLAGS) -o bin/$(BINARY_NAME)-windows-arm64.exe .

# Clean build artifacts
.PHONY: clean
clean:
	rm -rf bin/ coverage.out coverage.html

# Run unit tests (default)
.PHONY: test
test: test-unit

# Run unit tests
.PHONY: test-unit
test-unit:
	@echo "Running unit tests..."
	@./scripts/test.sh --unit-only

# Run integration tests
.PHONY: test-integration
test-integration:
	@echo "Running integration tests..."
	@./scripts/test.sh --integration-only

# Run all tests (unit + integration)
.PHONY: test-all
test-all:
	@echo "Running all tests..."
	@./scripts/test.sh --all

# Run tests with coverage
.PHONY: test-coverage
test-coverage:
	@echo "Running tests with coverage..."
	@./scripts/test.sh --unit-only --verbose

# Run tests in verbose mode
.PHONY: test-verbose
test-verbose:
	@echo "Running tests in verbose mode..."
	@./scripts/test.sh --unit-only --verbose

# Run linter
.PHONY: lint
lint:
	golangci-lint run

# Format code
.PHONY: fmt
fmt:
	go fmt ./...

# Install dependencies
.PHONY: deps
deps:
	go mod download
	go mod tidy

# Install the binary
.PHONY: install
install:
	go install $(LDFLAGS) .

# Development build and run
.PHONY: dev
dev: build
	./bin/$(BINARY_NAME)

# Help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build        - Build for current platform"
	@echo "  build-all    - Build for all platforms"
	@echo "  build-linux  - Build for Linux (amd64, arm64) with static compilation"
	@echo "  build-linux-compat - Build for Linux with maximum compatibility"
	@echo "  build-darwin - Build for macOS (amd64, arm64)"
	@echo "  build-windows- Build for Windows (amd64, arm64)"
	@echo "  clean        - Clean build artifacts"
	@echo "  test         - Run unit tests (default)"
	@echo "  test-unit    - Run unit tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  test-all     - Run all tests (unit + integration)"
	@echo "  test-coverage - Run tests with coverage report"
	@echo "  test-verbose - Run tests in verbose mode"
	@echo "  lint         - Run linter"
	@echo "  fmt          - Format code"
	@echo "  deps         - Install dependencies"
	@echo "  install      - Install binary to GOPATH/bin"
	@echo "  dev          - Build and run for development"
	@echo "  help         - Show this help" 