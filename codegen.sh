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

# Set up the correct directory structure in temp
mkdir -p "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/apis/topology/v1alpha1"
cp ${SCRIPT_ROOT}/pkg/apis/topology/v1alpha1/* "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/apis/topology/v1alpha1/"

# Add boilerplate if it doesn't exist
mkdir -p "${TEMP_DIR}/src/${PROJECT_MODULE}/hack"
cp ${SCRIPT_ROOT}/hack/boilerplate.go.txt "${TEMP_DIR}/src/${PROJECT_MODULE}/hack/"

cd "${TEMP_DIR}/src/${PROJECT_MODULE}"

# Use generate-groups.sh directly
${CODEGEN_PKG}/generate-groups.sh all \
    ${PROJECT_MODULE}/pkg/generated \
    ${PROJECT_MODULE}/pkg/apis \
    topology:v1alpha1 \
    --go-header-file hack/boilerplate.go.txt \
    --output-base "${TEMP_DIR}/src"

# Create target directory
mkdir -p "${SCRIPT_ROOT}/pkg/generated"

# Copy generated files back
if [ -d "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/generated" ]; then
    echo "Copying generated files back..."
    cp -r "${TEMP_DIR}/src/${PROJECT_MODULE}/pkg/generated"/* "${SCRIPT_ROOT}/pkg/generated/"
    echo "Generated code copied successfully"
else
    echo "ERROR: Generated directory not found. Contents of temp dir:"
    find "${TEMP_DIR}" -type f
fi

# Cleanup
rm -rf "${TEMP_DIR}"
