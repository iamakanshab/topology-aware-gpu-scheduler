#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Get absolute paths
ROOT_DIR=$(realpath $(dirname "${BASH_SOURCE[0]}")/.. )
CODEGEN_PKG=$(go env GOPATH)/pkg/mod/k8s.io/code-generator@v0.28.0
API_PKG_PATH="github.com/iamakanshab/topology-aware-gpu-scheduler"

# Verify boilerplate file exists
if [ ! -f "${ROOT_DIR}/boilerplate.go.txt" ]; then
    echo "Error: boilerplate.go.txt not found"
    exit 1
fi

echo "Root directory: ${ROOT_DIR}"
echo "API Package: ${API_PKG_PATH}"
echo "Boilerplate file: ${ROOT_DIR}/boilerplate.go.txt"

# Create a temporary build directory
TEMP_DIR=$(mktemp -d)
echo "Using temp directory: ${TEMP_DIR}"

# Create the full directory structure in temp
mkdir -p "${TEMP_DIR}/src/${API_PKG_PATH}"
cp -r "${ROOT_DIR}"/* "${TEMP_DIR}/src/${API_PKG_PATH}/"

# Verify the copy worked
if [ ! -f "${TEMP_DIR}/src/${API_PKG_PATH}/boilerplate.go.txt" ]; then
    echo "Error: Failed to copy boilerplate file"
    exit 1
fi

# Run the generator from the temp directory
cd "${TEMP_DIR}/src/${API_PKG_PATH}"

echo "Running code generator..."
"${CODEGEN_PKG}/kube_codegen.sh" \
  "client,informer,lister" \
  ${API_PKG_PATH}/pkg/generated \
  ${API_PKG_PATH}/pkg/apis \
  "topology:v1alpha1" \
  --output-base "${TEMP_DIR}/src" \
  --go-header-file boilerplate.go.txt

# Copy the generated files back
mkdir -p "${ROOT_DIR}/pkg/generated"
cp -r "${TEMP_DIR}/src/${API_PKG_PATH}/pkg/generated"/* "${ROOT_DIR}/pkg/generated/"

# Cleanup
rm -rf "${TEMP_DIR}"

echo "Code generation complete!"
