# Build variables
REGISTRY ?= localhost:5000
IMAGE_NAME ?= topology-scheduler
TAG ?= latest
FULL_IMAGE_NAME = $(REGISTRY)/$(IMAGE_NAME):$(TAG)

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
BINARY_NAME=topology-scheduler
MAIN_PATH=cmd/scheduler/main.go

# Build flags
LDFLAGS=-ldflags "-X main.version=$(TAG) -X main.buildDate=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')"
CGO_ENABLED=0
GOOS?=$(shell go env GOOS)
GOARCH?=$(shell go env GOARCH)

# Kubernetes related
KUBECONFIG ?= $(HOME)/.kube/config
NAMESPACE ?= kube-system

# Testing
COVERAGE_DIR=coverage
COVERAGE_PROFILE=$(COVERAGE_DIR)/coverage.out
COVERAGE_HTML=$(COVERAGE_DIR)/coverage.html

# Development tools
TOOLS_DIR := hack/tools
TOOLS_BIN_DIR := $(TOOLS_DIR)/bin
GOLANGCI_LINT := $(TOOLS_BIN_DIR)/golangci-lint
CONTROLLER_GEN := $(TOOLS_BIN_DIR)/controller-gen
MOCKGEN := $(TOOLS_BIN_DIR)/mockgen

.PHONY: all build clean test coverage lint deps docker-build docker-push deploy help

all: lint test build

# Build the binary
build: deps
	CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) $(GOBUILD) $(LDFLAGS) -o bin/$(BINARY_NAME) $(MAIN_PATH)

# Clean build artifacts
clean:
	$(GOCLEAN)
	rm -rf bin/
	rm -rf $(COVERAGE_DIR)
	rm -rf $(TOOLS_BIN_DIR)

# Run tests
test:
	mkdir -p $(COVERAGE_DIR)
	$(GOTEST) -v -race -coverprofile=$(COVERAGE_PROFILE) ./...

# Generate test coverage report
coverage: test
	$(GOCMD) tool cover -html=$(COVERAGE_PROFILE) -o $(COVERAGE_HTML)
	@echo "Coverage report generated at $(COVERAGE_HTML)"

# Install dependencies
deps:
	$(GOMOD) download
	$(GOMOD) tidy

# Run linter
lint: $(GOLANGCI_LINT)
	$(GOLANGCI_LINT) run --timeout=5m

# Build Docker image
docker-build:
	docker build -t $(FULL_IMAGE_NAME) .

# Push Docker image
docker-push:
	docker push $(FULL_IMAGE_NAME)

# Deploy to Kubernetes
deploy:
	kubectl apply -f deploy/crds/
	kubectl apply -f deploy/rbac/
	kubectl apply -f deploy/config/
	kubectl apply -f deploy/scheduler/

# Generate Kubernetes resources
generate: $(CONTROLLER_GEN)
	$(CONTROLLER_GEN) \
		crd \
		paths="./..." \
		output:crd:artifacts:config=deploy/crds

# Generate mocks for testing
mocks: $(MOCKGEN)
	@echo "Generating mocks..."
	$(MOCKGEN) -package=mock -destination=pkg/mock/scheduler.go github.com/your-org/topology-scheduler/pkg/scheduler Scheduler

# Install required tools
$(GOLANGCI_LINT):
	@mkdir -p $(TOOLS_BIN_DIR)
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(TOOLS_BIN_DIR) v1.55.2

$(CONTROLLER_GEN):
	@mkdir -p $(TOOLS_BIN_DIR)
	GOBIN=$(TOOLS_BIN_DIR) go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.13.0

$(MOCKGEN):
	@mkdir -p $(TOOLS_BIN_DIR)
	GOBIN=$(TOOLS_BIN_DIR) go install github.com/golang/mock/mockgen@v1.6.0

# Run the scheduler locally
run: build
	./bin/$(BINARY_NAME) --kubeconfig=$(KUBECONFIG) --v=2

# Run integration tests
integration-test:
	$(GOTEST) -v -tags=integration ./test/integration/...

# Update Go dependencies
update-deps:
	$(GOGET) -u ./...
	$(GOMOD) tidy

# Verify all generated files are up to date
verify: generate
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "Generated files are not up to date. Please run 'make generate' and commit the changes."; \
		git status --porcelain; \
		exit 1; \
	fi

# Show help
help:
	@echo "Available targets:"
	@echo "  build            - Build the scheduler binary"
	@echo "  clean            - Clean build artifacts"
	@echo "  test             - Run unit tests"
	@echo "  coverage         - Generate test coverage report"
	@echo "  lint             - Run linter"
	@echo "  deps             - Install dependencies"
	@echo "  docker-build     - Build Docker image"
	@echo "  docker-push      - Push Docker image"
	@echo "  deploy           - Deploy to Kubernetes"
	@echo "  generate         - Generate Kubernetes resources"
	@echo "  mocks            - Generate mocks for testing"
	@echo "  run              - Run scheduler locally"
	@echo "  integration-test - Run integration tests"
	@echo "  update-deps      - Update Go dependencies"
	@echo "  verify           - Verify generated files"
	@echo "  help             - Show this help message"

# Default target
.DEFAULT_GOAL := help
