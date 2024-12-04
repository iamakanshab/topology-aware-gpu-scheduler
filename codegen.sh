#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Get absolute paths
SCRIPT_ROOT=$(realpath $(dirname "${BASH_SOURCE[0]}")/.. )
PROJECT_MODULE="github.com/iamakanshab/topology-aware-gpu-scheduler"
CODEGEN_PKG=$(realpath $(go env GOPATH))/pkg/mod/k8s.io/code-generator@v0.28.0

echo "Script root: ${SCRIPT_ROOT}"
echo "Code generator package: ${CODEGEN_PKG}"

# Create a temp directory with proper permissions
TEMP_DIR=$(mktemp -d)
chmod 755 ${TEMP_DIR}
echo "Using temp directory: ${TEMP_DIR}"

# Ensure directories exist
mkdir -p "${SCRIPT_ROOT}/pkg/generated"

echo "Generating client codes..."
bash "${CODEGEN_PKG}/kube_codegen.sh" \
  "client,lister,informer" \
  ${PROJECT_MODULE}/pkg/generated \
  ${PROJECT_MODULE}/pkg/apis \
  "topology:v1alpha1" \
  --go-header-file "${SCRIPT_ROOT}/hack/boilerplate.go.txt" \
  --output-base "${TEMP_DIR}"

echo "Copying generated files..."
# Create target directory if it doesn't exist
mkdir -p "${SCRIPT_ROOT}/pkg/generated"

# Copy the generated files
if [ -d "${TEMP_DIR}/${PROJECT_MODULE}/pkg/generated" ]; then
    cp -r "${TEMP_DIR}/${PROJECT_MODULE}/pkg/generated"/* "${SCRIPT_ROOT}/pkg/generated/"
    echo "Generated code copied successfully"
else
    echo "Error: Generated directory not found at ${TEMP_DIR}/${PROJECT_MODULE}/pkg/generated"
    exit 1
fi

# Cleanup
rm -rf "${TEMP_DIR}"
echo "Cleanup complete"
