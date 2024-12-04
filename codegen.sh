#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Absolute paths
REPO_ROOT=$(realpath $(dirname "${BASH_SOURCE[0]}")/.. )
PROJECT_MODULE="github.com/iamakanshab/topology-aware-gpu-scheduler"
CODEGEN_PKG=$(go env GOPATH)/pkg/mod/k8s.io/code-generator@v0.28.0
TEMP_DIR=$(mktemp -d)
echo "Using temp dir: ${TEMP_DIR}"

# Set up directory structure
echo "Setting up directory structure..."
mkdir -p "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/apis/topology/v1alpha1"
mkdir -p "${TEMP_DIR}/src/${PROJECT_MODULE}/hack"

# Copy API files
echo "Copying API files..."
cp -r "${REPO_ROOT}/pkg/apis" "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/"
cp "${REPO_ROOT}/hack/boilerplate.go.txt" "${TEMP_DIR}/src/${PROJECT_MODULE}/hack/"

echo "Verifying copied files..."
ls -la "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/apis/topology/v1alpha1/"

# Change to the temp directory
cd "${TEMP_DIR}/src/${PROJECT_MODULE}"

echo "Running code generator..."
"${CODEGEN_PKG}/generate-groups.sh" all \
  "${PROJECT_MODULE}/pkg/generated" \
  "${PROJECT_MODULE}/pkg/apis" \
  "topology:v1alpha1" \
  --output-base "${TEMP_DIR}/src" \
  --go-header-file hack/boilerplate.go.txt

echo "Checking generated files..."
ls -la "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/generated" || true

# Copy generated files back
if [ -d "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/generated" ]; then
    echo "Copying generated files back..."
    mkdir -p "${REPO_ROOT}/pkg/generated"
    cp -r "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/generated"/* "${REPO_ROOT}/pkg/generated/"
    echo "Generated code copied successfully"
else
    echo "ERROR: Generated directory not found"
    echo "Contents of temp directory:"
    find "${TEMP_DIR}/src/${PROJECT_MODULE}" -type f
    exit 1
fi

# Cleanup
rm -rf "${TEMP_DIR}"
echo "Done!"
