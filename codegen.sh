#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Ensure GOPATH is set
GOPATH=$(go env GOPATH)
if [ -z "${GOPATH}" ]; then
    echo "GOPATH is not set"
    exit 1
fi

SCRIPT_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
PROJECT_ROOT="$SCRIPT_ROOT"
MODULE_NAME="topology-aware-gpu-scheduler"

# Ensure the code-generator module is downloaded
go get -d k8s.io/code-generator@v0.28.0
CODEGEN_PKG="${GOPATH}/pkg/mod/k8s.io/code-generator@v0.28.0"

echo "Generating client codes..."
bash "${CODEGEN_PKG}/generate-groups.sh" "deepcopy,client,informer,lister" \
  ${MODULE_NAME}/pkg/generated \
  ${MODULE_NAME}/pkg/apis \
  "topology:v1alpha1" \
  --go-header-file "${SCRIPT_ROOT}/hack/boilerplate.go.txt" \
  --output-base "${PROJECT_ROOT}"

# The generated code will be in the wrong location, so we need to move it
mv "${PROJECT_ROOT}/${MODULE_NAME}/pkg/generated" "${PROJECT_ROOT}/pkg/"
rm -rf "${PROJECT_ROOT}/${MODULE_NAME}"
