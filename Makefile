# Makefile
VERSION ?= latest
BUILD_DATE = $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

.PHONY: all
all: build

.PHONY: build
build:
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
        -ldflags "-X main.version=$(VERSION) -X main.buildDate=$(BUILD_DATE)" \
        -o bin/topology-scheduler cmd/scheduler/main.go

.PHONY: test
test:
    go test -v ./...

.PHONY: clean
clean:
    rm -rf bin/

.PHONY: deps
deps:
    go mod download
    go mod tidy

.PHONY: docker
docker:
    docker build -t topology-scheduler:$(VERSION) .
