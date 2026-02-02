#!/usr/bin/env bash

# Usage: ./hacking/local-test.sh
set -euo pipefail

# shellcheck disable=SC2317
cleanup_tests() {
    popd >/dev/null 2>&1 || true
    rm -rf "${COLLECTION_TMP_DIR}/ansible_collections"
    rm -rf "${COLLECTION_TMP_DIR}/collections"
}

: "${COLLECTION_TMP_DIR:=.}"

# Run build, which will remove previously installed versions
./hacking/build.sh

# Install new built version
ansible-galaxy collection install netbox-netbox-*.tar.gz \
    --force \
    --collections-path "$COLLECTION_TMP_DIR"


trap cleanup_tests EXIT INT TERM

# You can now cd into the installed version and run tests
mkdir -p "${COLLECTION_TMP_DIR}"
pushd "${COLLECTION_TMP_DIR}/ansible_collections/netbox/netbox/" >/dev/null || exit 1

# Detect Python version (use PYTHON_VERSION env var or auto-detect)
PYTHON_VERSION="${PYTHON_VERSION:-$(python3 --version | grep -oP '\d+\.\d+')}"
echo "Using Python version: ${PYTHON_VERSION}"

ansible-test units -v --python "${PYTHON_VERSION}"
ansible-test sanity --requirements -v --python "${PYTHON_VERSION}" --skip-test pep8 plugins/

