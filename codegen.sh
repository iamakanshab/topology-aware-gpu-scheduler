#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Ensure the go modules are downloaded
go mod download

# Define your module name
MODULE="your.module/name"

# Run the generators
go run k8s.io/code-generator/cmd/client-gen \
  --input-dirs ${MODULE}/pkg/apis/topology/v1alpha1 \
  --output-package ${MODULE}/pkg/generated/clientset \
  --clientset-name versioned \
  --go-header-file boilerplate.go.txt

go run k8s.io/code-generator/cmd/informer-gen \
  --input-dirs ${MODULE}/pkg/apis/topology/v1alpha1 \
  --versioned-clientset-package ${MODULE}/pkg/generated/clientset/versioned \
  --listers-package ${MODULE}/pkg/generated/listers \
  --output-package ${MODULE}/pkg/generated/informers \
  --go-header-file boilerplate.go.txt
