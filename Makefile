# Build variables
VERSION ?= latest
BUILD_DATE = $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
BINARY_NAME = topology-scheduler
GOARCH = amd64

# Determine OS-specific variables
ifeq ($(OS),Windows_NT)
    BINARY_SUFFIX = .exe
    RM = del /F /Q
    MKDIR = mkdir
else
    BINARY_SUFFIX =
    RM = rm -f
    MKDIR = mkdir -p
endif

# Directories
BIN_DIR = bin
PKG_DIR = pkg
CMD_DIR = cmd

# Go build flags
LDFLAGS = -ldflags "-X main.version=$(VERSION) -X main.buildDate=$(BUILD_DATE)"
GOFLAGS = CGO_ENABLED=0

.PHONY: all
all: clean deps install-deps build

.PHONY: clean
clean:
	$(RM) $(BIN_DIR)$(BINARY_NAME)$(BINARY_SUFFIX)
	go clean -modcache

.PHONY: deps
deps:
	go mod download
	go mod tidy
	go mod vendor

.PHONY: install-deps
install-deps:
	@echo "Installing required dependencies..."
	@if [ -f go.mod ]; then \
		go get -d github.com/yourusername/topology-aware-gpu-scheduler/pkg/generated/clientset/versioned; \
		go get -d github.com/yourusername/topology-aware-gpu-scheduler/pkg/scheduler/algorithm; \
		go get -d github.com/prometheus/client_golang/prometheus/promhttp; \
		go get -d k8s.io/apimachinery/pkg/apis/meta/v1@v0.28.0; \
		go get -d k8s.io/client-go/kubernetes@v0.28.0; \
		go get -d k8s.io/client-go/tools/clientcmd@v0.28.0; \
		go get -d k8s.io/client-go/tools/leaderelection@v0.28.0; \
		go get -d k8s.io/client-go/tools/leaderelection/resourcelock@v0.28.0; \
		go get -d k8s.io/kubernetes/pkg/scheduler/apis/config@v1.28.0; \
		go get -d k8s.io/kube-scheduler@v0.28.0; \
		go mod tidy; \
		go mod vendor; \
	else \
		echo "Error: go.mod not found. Please run 'make init-modules' first."; \
		exit 1; \
	fi

.PHONY: build
build:
	$(MKDIR) $(BIN_DIR)
	$(GOFLAGS) go build $(LDFLAGS) -o $(BIN_DIR)/$(BINARY_NAME)$(BINARY_SUFFIX) $(CMD_DIR)/scheduler/main.go

.PHONY: test
test:
	go test -v ./...

.PHONY: test-coverage
test-coverage:
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out

.PHONY: lint
lint:
	golangci-lint run

.PHONY: run
run: build
	./$(BIN_DIR)/$(BINARY_NAME)$(BINARY_SUFFIX)

.PHONY: generate
generate:
	go generate ./...

.PHONY: docker
docker:
	docker build -t $(BINARY_NAME):$(VERSION) .

.PHONY: setup
setup: deps install-deps build

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all            - Clean, get dependencies, install required packages, and build"
	@echo "  clean          - Remove built binary and clean go cache"
	@echo "  deps           - Download and tidy dependencies"
	@echo "  install-deps   - Install specific required dependencies"
	@echo "  build          - Build the binary"
	@echo "  test           - Run tests"
	@echo "  test-coverage  - Run tests with coverage report"
	@echo "  lint           - Run linter"
	@echo "  run            - Build and run the binary"
	@echo "  generate       - Run go generate"
	@echo "  docker         - Build Docker image"
	@echo "  setup          - Complete setup (deps, install-deps, build)"
