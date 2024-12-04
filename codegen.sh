#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -x  # Enable command printing for debugging

SCRIPT_ROOT=$(realpath $(dirname "${BASH_SOURCE[0]}")/.. )
PROJECT_MODULE="github.com/iamakanshab/topology-aware-gpu-scheduler"
CODEGEN_PKG=$(go env GOPATH)/pkg/mod/k8s.io/code-generator@v0.28.0

echo "Current directory: $(pwd)"
echo "Script root: ${SCRIPT_ROOT}"
echo "Code generator package: ${CODEGEN_PKG}"

# Verify directories and files
echo "Verifying directory structure..."
ls -la ${SCRIPT_ROOT}/pkg/apis/topology/v1alpha1/

# Create temp directory
TEMP_DIR=$(mktemp -d)
echo "Created temp directory: ${TEMP_DIR}"

# Create the full directory structure in temp
mkdir -p "${TEMP_DIR}/src/${PROJECT_MODULE}"
echo "Copying project files..."
cp -r "${SCRIPT_ROOT}/." "${TEMP_DIR}/src/${PROJECT_MODULE}/"

cd "${TEMP_DIR}/src/${PROJECT_MODULE}"
echo "Working directory: $(pwd)"
ls -la

# Use generate-groups.sh directly
${CODEGEN_PKG}/generate-groups.sh all \
    ${PROJECT_MODULE}/pkg/generated \
    ${PROJECT_MODULE}/pkg/apis \
    "topology:v1alpha1" \
    --go-header-file "${SCRIPT_ROOT}/hack/boilerplate.go.txt" \
    --output-base "${TEMP_DIR}/src"

echo "Checking generated files..."
ls -la "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/generated" || true

# Create target directory
mkdir -p "${SCRIPT_ROOT}/pkg/generated"

# Copy generated files back
if [ -d "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/generated" ]; then
    echo "Copying generated files back..."
    cp -r "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/generated"/* "${SCRIPT_ROOT}/pkg/generated/"
else
    echo "ERROR: Generated directory not found. Contents of temp dir:"
    ls -la "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/"
    echo "Contents of apis directory:"
    ls -la "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/apis/topology/v1alpha1/"
fi

# Cleanup
rm -rf "${TEMP_DIR}"
