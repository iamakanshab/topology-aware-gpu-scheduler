#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname $(realpath "${BASH_SOURCE[0]}"))
ROOT_DIR=$(pwd)
CODEGEN_PKG=$(go env GOPATH)/pkg/mod/k8s.io/code-generator@v0.28.0
API_PKG_PATH="github.com/iamakanshab/topology-aware-gpu-scheduler"

# Create a temporary build directory
TEMP_DIR=$(mktemp -d)
echo "Using temp directory: ${TEMP_DIR}"

# Create the full directory structure in temp
mkdir -p "${TEMP_DIR}/src/${API_PKG_PATH}"
cp -r "${ROOT_DIR}"/* "${TEMP_DIR}/src/${API_PKG_PATH}/"

# Run the generator from the temp directory
cd "${TEMP_DIR}/src/${API_PKG_PATH}"

echo "Running code generator..."

GOPATH="${TEMP_DIR}" GO111MODULE=on "${CODEGEN_PKG}/generate-groups.sh" \
  "client,informer,lister,deepcopy" \
  "${API_PKG_PATH}/pkg/generated" \
  "${API_PKG_PATH}/pkg/apis" \
  "topology:v1alpha1" \
  --output-base "${TEMP_DIR}/src" \
  --go-header-file "${PWD}/boilerplate.go.txt" \
  --trim-path-prefix "${API_PKG_PATH}"

# Copy the generated files back
mkdir -p "${ROOT_DIR}/pkg/generated"
cp -r "${TEMP_DIR}/src/${API_PKG_PATH}/pkg/generated"/* "${ROOT_DIR}/pkg/generated/" || true

# Cleanup
rm -rf "${TEMP_DIR}"
echo "Code generation complete!"
