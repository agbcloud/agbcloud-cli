# Build variables
BINARY_NAME=agb
VERSION?=dev
GIT_COMMIT?=$(shell git rev-parse --short HEAD)
BUILD_DATE?=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build flags (with optimization)
LDFLAGS=-ldflags "-s -w -X github.com/agbcloud/agbcloud-cli/cmd.Version=$(VERSION) -X github.com/agbcloud/agbcloud-cli/cmd.GitCommit=$(GIT_COMMIT) -X github.com/agbcloud/agbcloud-cli/cmd.BuildDate=$(BUILD_DATE)"

# Default target
.PHONY: all
all: build

# Build for current platform
.PHONY: build
build:
	go build $(LDFLAGS) -o bin/$(BINARY_NAME) .

# Build for all platforms (existing individual targets)
.PHONY: build-all
build-all: build-linux build-darwin build-windows

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

# Unified build target (类似 actions-batch 风格)
.PHONY: dist
dist:
	mkdir -p bin
	# macOS builds (Homebrew 支持)
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build $(LDFLAGS) -o bin/$(BINARY_NAME)-darwin-amd64 .
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build $(LDFLAGS) -o bin/$(BINARY_NAME)-darwin-arm64 .
	# Linux builds (Homebrew 支持)
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o bin/$(BINARY_NAME)-linux-amd64 .
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build $(LDFLAGS) -o bin/$(BINARY_NAME)-linux-arm64 .
	# Windows builds (不被 Homebrew 支持，但可用于其他分发)
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o bin/$(BINARY_NAME)-windows-amd64.exe .
	CGO_ENABLED=0 GOOS=windows GOARCH=arm64 go build $(LDFLAGS) -o bin/$(BINARY_NAME)-windows-arm64.exe .

# Generate hash files
.PHONY: hash
hash:
	cd bin && find . -name "$(BINARY_NAME)-*" -type f | xargs -I {} sh -c 'sha256sum "{}" > "{}.sha256"'

# Clean build artifacts
.PHONY: clean
clean:
	rm -rf bin/ coverage.out coverage.html

# Run tests
.PHONY: test
test:
	go test ./... -cover

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
	@echo "  build-all    - Build for all platforms (individual targets)"
	@echo "  dist         - Build for all platforms (unified target)"
	@echo "  hash         - Generate SHA256 hash files"
	@echo "  clean        - Clean build artifacts"
	@echo "  test         - Run tests"
	@echo "  lint         - Run linter"
	@echo "  fmt          - Format code"
	@echo "  deps         - Install dependencies"
	@echo "  install      - Install binary to GOPATH/bin"
	@echo "  dev          - Build and run for development"
	@echo "  help         - Show this help"