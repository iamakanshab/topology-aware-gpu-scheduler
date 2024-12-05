#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname $(realpath "${BASH_SOURCE[0]}"))
ROOT_DIR=$(pwd)
CODEGEN_PKG=$(go env GOPATH)/pkg/mod/k8s.io/code-generator@v0.28.0
API_PKG_PATH="github.com/iamakanshab/topology-aware-gpu-scheduler"

# Create a temporary build directory with proper permissions
TEMP_DIR=$(mktemp -d)
chmod 755 "${TEMP_DIR}"
echo "Using temp directory: ${TEMP_DIR}"

# Create the full directory structure in temp
mkdir -p "${TEMP_DIR}/src/${API_PKG_PATH}"
cp -r "${ROOT_DIR}"/* "${TEMP_DIR}/src/${API_PKG_PATH}/"

# Set permissions recursively
chmod -R 755 "${TEMP_DIR}"

# Run the generator from the temp directory
cd "${TEMP_DIR}/src/${API_PKG_PATH}"

echo "Running code generator..."
GOPATH="${TEMP_DIR}" GO111MODULE=on "${CODEGEN_PKG}/generate-groups.sh" \
  "client,informer,lister,deepcopy" \
  "${API_PKG_PATH}/pkg/generated" \
  "${API_PKG_PATH}/pkg/apis" \
  "topology:v1alpha1" \
  --output-base "${TEMP_DIR}/src" \
  --go-header-file "${PWD}/boilerplate.go.txt"

# Copy the generated files back
if [ -d "${TEMP_DIR}/src/${API_PKG_PATH}/pkg/generated" ]; then
    mkdir -p "${ROOT_DIR}/pkg/generated"
    cp -r "${TEMP_DIR}/src/${API_PKG_PATH}/pkg/generated"/* "${ROOT_DIR}/pkg/generated/"
fi

# Cleanup with sudo if needed
if [ -d "${TEMP_DIR}" ]; then
    sudo rm -rf "${TEMP_DIR}"
fi

echo "Code generation complete!"
