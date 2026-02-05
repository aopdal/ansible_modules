#!/usr/bin/env bash
#
# Update Test Inventory JSON Files
#
# This script regenerates the expected JSON output files for inventory tests
# by running the inventory plugin against a live NetBox instance.
#
# Usage: ./hacking/update_test_inventories.sh [VERSION]
#
# Prerequisites:
#   1. NetBox Docker running: ./netbox-docker-helper.sh start v4.3
#   2. Test data populated: ./netbox-docker-helper.sh populate
#
# Examples:
#   ./hacking/update_test_inventories.sh v4.3
#   ./hacking/update_test_inventories.sh v4.4
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
VERSION="${1:-v4.3}"
INVENTORY_DIR="$REPO_DIR/tests/integration/targets/inventory-$VERSION"

# Cleanup function to remove installed collection
cleanup() {
    if [ -d "$REPO_DIR/ansible_collections" ]; then
        echo "Cleaning up installed collection..."
        rm -rf "$REPO_DIR/ansible_collections"
    fi
}

# Ensure cleanup runs on exit (success or failure)
trap cleanup EXIT

if [ ! -d "$INVENTORY_DIR" ]; then
    echo "ERROR: Inventory test directory not found: $INVENTORY_DIR"
    echo "Available versions:"
    ls -d "$REPO_DIR/tests/integration/targets/inventory-v"* 2>/dev/null | xargs -n1 basename | sed 's/inventory-/  /'
    exit 1
fi

echo "================================"
echo "Updating inventory test data for $VERSION"
echo "================================"
echo ""
echo "Inventory directory: $INVENTORY_DIR"
echo ""

# Install locally so ansible can find the collection
export ANSIBLE_COLLECTIONS_PATHS="$REPO_DIR"

# Use the repo's ansible.cfg for consistent group name normalization
export ANSIBLE_CONFIG="$REPO_DIR/ansible.cfg"

# Set output directory for JSON files
export OUTPUT_INVENTORY_JSON="$INVENTORY_DIR/files"

# Set OUTPUT_DIR for runme.sh (it expects this when OUTPUT_INVENTORY_JSON is set)
export OUTPUT_DIR="$INVENTORY_DIR/files"

# Set the NetBox version for comparison script
export NETBOX_VERSION="$VERSION"

# Remove local cache to ensure fresh data
rm -rf /tmp/inventory_netbox/

# Build and install the collection
echo "Building and installing collection..."
cd "$REPO_DIR"
./hacking/build.sh

# Install collection locally
ansible-galaxy collection install netbox-netbox-*.tar.gz \
    --force \
    --collections-path "$REPO_DIR"

echo ""
echo "Running inventory tests to generate JSON files..."
echo ""

# Run the runme.sh script which will generate and save the JSON files
cd "$INVENTORY_DIR"
./runme.sh

echo ""
echo "================================"
echo "Inventory JSON files updated!"
echo "================================"
echo ""
echo "Review the changes:"
echo "  git diff $INVENTORY_DIR/files/*.json"
echo ""
echo "If changes look correct, commit them."
