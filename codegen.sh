#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
CODEGEN_PKG=${CODEGEN_PKG:-$(cd "${SCRIPT_ROOT}"; ls -d -1 ./vendor/k8s.io/code-generator 2>/dev/null || echo $(go env GOPATH)/pkg/mod/k8s.io/code-generator@v0.28.0)}

# Create temporary directory for code generation
TMP_DIR=$(mktemp -d)
chmod 755 $TMP_DIR

echo "Generating client codes..."
bash "${CODEGEN_PKG}/kube_codegen.sh" \
  "client,lister,informer" \
  github.com/yourusername/topology-aware-gpu-scheduler/pkg/generated \
  github.com/yourusername/topology-aware-gpu-scheduler/pkg/apis \
  "topology:v1alpha1" \
  --output-base "${TMP_DIR}" \
  --go-header-file "${SCRIPT_ROOT}/hack/boilerplate.go.txt"

# Copy generated files to the right location
cp -r "${TMP_DIR}/github.com/yourusername/topology-aware-gpu-scheduler/pkg/generated" "${SCRIPT_ROOT}/pkg/"

# Cleanup
rm -rf "${TMP_DIR}"
