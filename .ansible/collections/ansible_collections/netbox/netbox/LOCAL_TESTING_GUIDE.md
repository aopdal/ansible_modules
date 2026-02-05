# Local Testing Guide for NetBox Ansible Collection

This guide walks you through the testing infrastructure and provides practical commands for running tests locally.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Test Types Explained](#test-types-explained)
5. [Running Tests Locally](#running-tests-locally)
6. [Integration Testing with Docker](#integration-testing-with-docker)
7. [Common Workflows](#common-workflows)
8. [Troubleshooting](#troubleshooting)

---

## Overview

The NetBox Ansible Collection uses a comprehensive testing strategy:

- **Unit Tests**: Fast, isolated tests using pytest (no NetBox required)
- **Sanity Tests**: Ansible code quality checks (ansible-test)
- **Integration Tests**: Full end-to-end tests against live NetBox Docker instances
- **Linting**: Code formatting (black), YAML (yamllint), and Ansible (ansible-lint)

**Test Matrix**: Tests run against NetBox versions 4.0, 4.1, 4.2, 4.3, 4.4, 4.5 with Python 3.11, 3.12, 3.13.

---

## Prerequisites

### Required Software

```bash
# Python 3.11+ (3.11, 3.12, or 3.13 all work)
python3 --version

# Poetry (dependency management)
curl -sSL https://install.python-poetry.org | python3 -

# Docker & Docker Compose (for integration tests)
docker --version
docker compose version  # V2 (recommended)
# or: docker-compose --version  # V1 (also supported)

# Ansible 2.18+
ansible --version
```

### Python Environment Setup

#### Option 1: Using Poetry (Recommended)

```bash
# Navigate to the cloned repository
cd /path/to/ansible_modules

# Install dependencies
poetry install

# Activate virtual environment
poetry shell
```

#### Option 2: Using virtualenv

```bash
# Create virtualenv
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install -r test-requirements.txt
pip install pytest pytest-mock pytest-xdist pytest-forked coverage deepdiff
```

### Collection Installation Structure

Ansible collections **must** be in a specific directory structure:

```text
ansible_collections/
└── netbox/
    └── netbox/
        ├── plugins/
        ├── tests/
        └── ...
```

The helper scripts handle this automatically, but if running tests manually, ensure you're in the correct path.

---

## Quick Start

### Fastest: Run Built-in Test Script

```bash
# Activate your venv first
source venv/bin/activate

# Build collection + run unit + sanity tests (auto-detects Python version)
./hacking/local-test.sh

# Or specify Python version explicitly
PYTHON_VERSION=3.12 ./hacking/local-test.sh
```

This script:

1. Builds the collection tarball
2. Installs it in proper ansible_collections structure
3. Runs unit tests (pytest)
4. Runs sanity tests (ansible-test)
5. Cleans up automatically

### Quick Formatting Check

```bash
# Format code with black
./hacking/black.sh

# Or manually:
black .
yamllint .
ansible-lint
```

---

## Test Types Explained

### 1. Unit Tests (pytest)

- **Location**: `tests/unit/`
- **What**: Tests for module_utils and plugin logic
- **Speed**: Fast (~seconds)
- **Requirements**: No NetBox instance needed

**Files tested**:

- `tests/unit/module_utils/netbox_utils/test_netbox_module.py` - 23 test functions
- `tests/unit/inventory/test_nb_inventory.py` - Inventory plugin tests

**Test data**: JSON files in `tests/unit/module_utils/test_data/netbox_utils/`

### 2. Sanity Tests (ansible-test)

- **What**: Code quality, Ansible compatibility, import checks
- **Speed**: Medium (~1-2 minutes)
- **Requirements**: No NetBox instance needed

**Checks include**:

- Python syntax validation
- Import statement verification
- Documentation validation
- Ansible module argument spec validation
- *Note: pep8 is skipped (use black instead)*

### 3. Integration Tests (ansible-test)

- **Location**: `tests/integration/targets/`
- **What**: Full module tests against live NetBox
- **Speed**: Slow (~10-30 minutes)
- **Requirements**: NetBox Docker instance + pre-populated data

**Test categories**:

- `v4.0/`, `v4.1/`, `v4.2/`, `v4.3/`, `v4.4/` - Main module tests (91 modules)
- `inventory-v4.x/` - Inventory plugin tests
- `regression-v4.x/` - Regression tests for known bugs

### 4. Linting

- **black**: Python code formatting (enforced)
- **yamllint**: YAML validation
- **ansible-lint**: Ansible playbook best practices

---

## Running Tests Locally

### Unit Tests

**Run all unit tests**:

```bash
# Using pytest directly
pytest -vv tests/unit/

# With coverage report
pytest -vv --cov=plugins/module_utils --cov-report=html tests/unit/

# Parallel execution (faster)
pytest -vv -n auto tests/unit/
```

**Run specific test file**:

```bash
pytest -vv tests/unit/module_utils/netbox_utils/test_netbox_module.py
```

**Run specific test function**:

```bash
pytest -vv tests/unit/module_utils/netbox_utils/test_netbox_module.py::test_normalize_data_returns_correct_data
```

**Using ansible-test** (after collection is installed):

```bash
ansible-test units -v --python 3.13
```

---

### Sanity Tests

```bash
# Run all sanity tests (skip pep8, use black instead)
ansible-test sanity --requirements -v --python 3.13 --skip-test pep8 plugins/

# Run specific sanity test
ansible-test sanity --test validate-modules -v plugins/modules/

# Test specific files
ansible-test sanity --test import plugins/modules/netbox_device.py
```

**Common sanity test types**:

- `import` - Check Python imports
- `validate-modules` - Validate module documentation
- `pylint` - Python code analysis
- `ansible-doc` - Documentation syntax

---

### Linting

**Black (required before commits)**:

```bash
# Check formatting
black --check .

# Auto-format
black .

# Or use the script
./hacking/black.sh
```

**YAML Linting**:

```bash
# Check all YAML files
yamllint .

# Check specific file
yamllint tests/integration/targets/v4.3/tasks/netbox_device.yml
```

**Ansible Linting**:

```bash
# Lint playbooks
ansible-lint

# Lint specific file
ansible-lint tests/integration/targets/v4.3/tasks/netbox_device.yml
```

---

## Integration Testing with Docker

Integration tests require a running NetBox instance with test data.

**Test Version Mapping**:

- `v4.0` tests → NetBox v4.0 Docker image
- `v4.1` tests → NetBox v4.1 Docker image (netbox-docker 3.0.2)
- `v4.2` tests → NetBox v4.2 Docker image (netbox-docker 3.2.1)
- `v4.3` tests → NetBox v4.3 Docker image (netbox-docker 3.3.0)
- `v4.4` tests → NetBox v4.4 Docker image (netbox-docker 3.4.2)
- `v4.5` tests → NetBox v4.5 Docker image (netbox-docker release branch)

### Quick Start: Using the Helper Script (Recommended)

A convenience script is provided to manage NetBox Docker instances:

```bash
# Start NetBox v4.3 (runs in background)
./netbox-docker-helper.sh start v4.3

# Wait ~2-3 minutes, then check status
./netbox-docker-helper.sh status

# Watch logs to see when ready (Ctrl+C to exit)
./netbox-docker-helper.sh logs
# Wait for: "Listening at: http://0.0.0.0:8080"

# Populate test data
./netbox-docker-helper.sh populate

# Run your tests (see Step 3 below)

# Stop NetBox when done
./netbox-docker-helper.sh stop
```

**Helper script commands**:

```bash
./netbox-docker-helper.sh start [v4.0|v4.1|v4.2|v4.3|v4.4|v4.5]  # Start NetBox
./netbox-docker-helper.sh populate                                # Load test data
./netbox-docker-helper.sh status                                  # Check if running
./netbox-docker-helper.sh logs                                    # Follow logs
./netbox-docker-helper.sh stop                                    # Stop & cleanup
./netbox-docker-helper.sh restart v4.3                            # Restart
./netbox-docker-helper.sh help                                    # Show help
```

#### NetBox v4.5+ and v2 API Tokens

Starting with NetBox v4.5 (using netbox-docker 4.0.0+), NetBox uses **v2 API tokens** which have a different format and authentication method:

**Token Format Differences**:

| Version | Format | Example | Auth Header |
|---------|--------|---------|-------------|
| v1 (v4.0-v4.4) | 40-char hex | `0123456789abcdef...` | `Authorization: Token <token>` |
| v2 (v4.5+) | `nbt_KEY.TOKEN` | `nbt_XWdV7GISgXjc.9sjhCYCr...` | `Authorization: Bearer <token>` |

**v2 Token Provisioning**:

For v4.5+, tokens cannot be pre-configured via environment variables. They must be provisioned dynamically via the API:

```bash
# Start NetBox v4.5 - token is automatically provisioned
./netbox-docker-helper.sh start v4.5

# The helper script will:
# 1. Start NetBox containers
# 2. Wait for NetBox to be ready
# 3. Automatically provision a v2 token via /api/users/tokens/provision/
# 4. Save token to /tmp/netbox-token.env

# Load the token into your environment
source /tmp/netbox-token.env

# Or manually provision a token if needed
./tests/netbox-docker/provision-token.sh
```

**Testing API Access**:

```bash
# For v2 tokens (v4.5+)
source /tmp/netbox-token.env
curl -H "Authorization: Bearer $NETBOX_TOKEN" \
     http://localhost:32768/api/dcim/sites/

# For v1 tokens (v4.0-v4.4)
curl -H "Authorization: Token 0123456789abcdef0123456789abcdef01234567" \
     http://localhost:32768/api/dcim/sites/
```

**Integration Tests with v4.5**:

The integration tests and populate script automatically detect v2 tokens:

```bash
# Standard workflow still applies
./netbox-docker-helper.sh start v4.5
./netbox-docker-helper.sh populate  # Uses v2 token automatically
./hacking/integration-test.sh v4.5  # Tests use v2 token

# The NETBOX_TOKEN environment variable is automatically used
# pynetbox detects the token format and uses the correct authentication
```

**Manual Token Provisioning**:

If you need to manually provision or check the token:

```bash
# Provision a new v2 token
NETBOX_TOKEN=$(./tests/netbox-docker/provision-token.sh)
echo "Token: $NETBOX_TOKEN"

# Export for use
export NETBOX_TOKEN="$NETBOX_TOKEN"

# Or source from saved file
source /tmp/netbox-token.env
```

**Troubleshooting v2 Tokens**:

If token provisioning fails:

1. Check NetBox is running: `curl http://localhost:32768/login/`
2. Check logs: `./netbox-docker-helper.sh logs`
3. Manually provision: `./tests/netbox-docker/provision-token.sh`
4. Verify token: `echo $NETBOX_TOKEN` (should start with `nbt_`)

**Behind the Scenes**:

- The `provision-token.sh` script calls the `/api/users/tokens/provision/` endpoint with admin credentials
- NetBox returns a `key` and `token` which are combined as `nbt_<key>.<token>`
- The `netbox-deploy.py` script detects v2 tokens (starting with `nbt_`) and uses them automatically
- The Ansible modules use pynetbox which automatically handles Bearer vs Token authentication

### All-in-One: Integration Test Script

For a complete test workflow (build, install dependencies, and run tests), use the integration test script:

```bash
# Prerequisites: NetBox Docker must be running (use netbox-docker-helper.sh)
# See above for starting NetBox and populating test data

# Run module tests for v4.3 (default is v4.5)
./hacking/integration-test.sh v4.3

# Run inventory tests
./hacking/integration-test.sh inventory-v4.3

# Run regression tests
./hacking/integration-test.sh regression-v4.3

# Run ALL tests for a version (modules + inventory + regression)
./hacking/integration-test.sh all-v4.3

# List available test targets
./hacking/integration-test.sh --list
```

This script automatically:

1. Builds the collection tarball
2. Installs collection dependencies (e.g., `community.general` for `json_query` filter)
3. Installs the collection in an isolated test environment
4. Runs the integration tests with `ansible-test`

**Test Target Types**:

| Target Type      | Example           | Description                               |
| ---------------- | ----------------- | ----------------------------------------- |
| Module Tests     | `v4.3`            | Main module tests (91 modules)            |
| Inventory Tests  | `inventory-v4.3`  | Tests the inventory plugin output         |
| Regression Tests | `regression-v4.3` | Tests for specific bug fixes              |
| All Tests        | `all-v4.3`        | Runs all available test types for version |

**Complete workflow example**:

```bash
# 1. Start NetBox and populate data
./netbox-docker-helper.sh start v4.3
./netbox-docker-helper.sh populate

# 2. Run all integration tests for v4.3
./hacking/integration-test.sh all-v4.3

# Or run specific test types:
./hacking/integration-test.sh v4.3           # Module tests only
./hacking/integration-test.sh inventory-v4.3  # Inventory tests only
./hacking/integration-test.sh regression-v4.3 # Regression tests only

# 3. Cleanup
./netbox-docker-helper.sh stop
```

### Manual Setup (Alternative)

<details>
<summary>Click to expand manual Docker setup instructions</summary>

#### Step 1: Start NetBox Docker

Choose a NetBox version (v4.0, v4.1, v4.2, v4.3 or v4.4):

```bash
# Clone netbox-docker if you don't have it
cd /tmp
git clone https://github.com/netbox-community/netbox-docker.git
cd netbox-docker

# For NetBox v4.3 (latest)
export VERSION=v4.3

# Copy the test override config
cp /path/to/ansible_modules/tests/netbox-docker/v4.3/docker-compose.override.yml .

# Start NetBox (runs in background with -d flag)
docker-compose pull
docker-compose up -d

# Wait for NetBox to be ready (can take 2-3 minutes)
docker-compose logs -f netbox
# Wait for: "Listening at: http://0.0.0.0:8080"
```

**Verify NetBox is running**:

```bash
curl http://localhost:32768/api/
# Should return API version info
```

#### Step 2: Pre-populate Test Data**

```bash
# Navigate to the repository root
cd /path/to/ansible_modules

# Run the deployment script to create test objects
python tests/integration/netbox-deploy.py

# Verify data was created
curl -H "Authorization: Token 0123456789abcdef0123456789abcdef01234567" \
  http://localhost:32768/api/dcim/sites/ | jq '.count'
# Should return count > 0
```

**Note**: The script expects NetBox at `http://localhost:32768` with token `0123456789abcdef0123456789abcdef01234567`

#### Step 3: Run Integration Tests**

```bash
# Activate venv and detect Python version
source venv/bin/activate
PYTHON_VERSION=$(python3 --version | grep -oP '\d+\.\d+')

# Run all v4.3 module tests
ansible-test integration -v --color --coverage --python "${PYTHON_VERSION}" v4.3

# Or run specific test targets
ansible-test integration -v --python "${PYTHON_VERSION}" inventory-v4.3
ansible-test integration -v --python "${PYTHON_VERSION}" regression-v4.3
```

#### Step 4: Inventory Tests (Special Case)

Inventory tests compare `ansible-inventory --list` output against expected JSON.

Manual inventory test run:

```bash
cd tests/integration/targets/inventory-v4.3/
./runme.sh
```

Update test data (after inventory plugin changes):

```bash
# From repo root
./hacking/update_test_inventories.sh
```

#### Step 5: Cleanup

```bash
# Stop NetBox Docker
cd /tmp/netbox-docker
docker-compose down -v  # -v removes volumes (clean state)
```

</details>

---

## Common Workflows

### Workflow 1: Quick Pre-Commit Check

```bash
# Activate venv
source venv/bin/activate

# Format code
black .

# Run fast tests
pytest -vv tests/unit/

# Quick sanity check (uses auto-detected Python version)
./quick-test.sh format
```

### Workflow 2: Full Local Test (No Docker)

```bash
# Activate venv
source venv/bin/activate

# Use the helper script (auto-detects Python version)
./hacking/local-test.sh

# Or use the quick-test wrapper
./quick-test.sh all
```

### Workflow 3: Developing a New Module

```bash
# Activate venv
source venv/bin/activate

# 1. Create module in plugins/modules/netbox_mynewmodule.py
# 2. Add test playbook in tests/integration/targets/v4.3/tasks/netbox_mynewmodule.yml
# 3. Update unit test data if needed

# Run unit tests
pytest -vv tests/unit/

# Format
black .

# Start NetBox Docker (see Integration Testing section)

# Run integration test for your module
PYTHON_VERSION=$(python3 --version | grep -oP '\d+\.\d+')
ansible-test integration -v --python "${PYTHON_VERSION}" v4.3 --allow-destructive
```

### Workflow 4: Running Integration Tests (Recommended)

```bash
# Activate venv
source venv/bin/activate

# 1. Start NetBox Docker (once, reusable for multiple test runs)
./netbox-docker-helper.sh start v4.3

# 2. Populate test data (if not already done)
./netbox-docker-helper.sh populate

# 3. Run integration tests (all-in-one script)
./hacking/integration-test.sh v4.3

# 4. Make code changes and re-test (no need to restart NetBox)
# Edit your code...
./hacking/integration-test.sh v4.3  # Run tests again

# 5. Cleanup when done
./netbox-docker-helper.sh stop
```

This workflow uses the all-in-one integration test script that handles building, dependency installation, and test execution automatically.

### Workflow 5: Testing Inventory Plugin Changes

```bash
# Activate venv
source venv/bin/activate

# 1. Make changes to plugins/inventory/nb_inventory.py
# 2. Start NetBox + pre-populate data (see Integration Testing section)
./netbox-docker-helper.sh start v4.3
./netbox-docker-helper.sh populate

# 3. Update test inventories for the version you're testing against
./hacking/update_test_inventories.sh v4.3

# 4. Review the diff
git diff tests/integration/targets/inventory-v4.3/files/*.json

# 5. Run inventory tests
./hacking/integration-test.sh inventory-v4.3

# 6. Cleanup
./netbox-docker-helper.sh stop
```

**Note**: The `update_test_inventories.sh` script regenerates the expected JSON output files.
Only commit these changes if the diff looks correct and intentional.

### Workflow 6: CI Simulation (Full Test Suite)

```bash
# IMPORTANT: Activate your venv first!
source venv/bin/activate

# Detect Python version
PYTHON_VERSION=$(python3 --version | grep -oP '\d+\.\d+')
echo "Using Python ${PYTHON_VERSION}"

# 1. Linting
black --check .
yamllint .
ansible-lint

# 2. Build and install
./hacking/build.sh
ansible-galaxy collection install netbox-netbox-*.tar.gz --force \
  --collections-path /tmp/test-collections

# 3. Unit tests with coverage
cd /tmp/test-collections/ansible_collections/netbox/netbox/
ansible-test units -v --python "${PYTHON_VERSION}" --coverage
ansible-test coverage report

# 4. Sanity tests
ansible-test sanity --requirements -v --python "${PYTHON_VERSION}" --skip-test pep8 plugins/

# 5. Integration tests (requires NetBox Docker)
ansible-test integration -v --color --coverage --python "${PYTHON_VERSION}" v4.3
ansible-test integration -v --python "${PYTHON_VERSION}" inventory-v4.3
ansible-test integration -v --python "${PYTHON_VERSION}" regression-v4.3

# 6. Coverage report
ansible-test coverage report
ansible-test coverage html
```

---

## Troubleshooting

### Issue: "Collection not found" during ansible-test

**Solution**: Ensure you're in the correct directory structure:

```bash
# Should be in: ansible_collections/netbox/netbox/
pwd
# Expected: /path/to/ansible_collections/netbox/netbox/

# If not, use the install script:
./hacking/local-test.sh
```

### Issue: Unit tests fail with import errors

**Solution**: Install test dependencies:

```bash
pip install pytest pytest-mock pytest-xdist pytest-forked coverage
# Or
poetry install
```

### Issue: NetBox Docker not accessible

**Check Docker is running**:

```bash
docker ps | grep netbox
# Should see: netbox, netbox-worker, postgres, redis containers
```

**Check NetBox health**:

```bash
curl http://localhost:32768/api/ | jq
# Should return API info

# Check logs
docker logs netbox-docker-netbox-1
```

**Verify port mapping**:

```bash
docker ps | grep netbox
# Should show: 0.0.0.0:32768->8080/tcp (or similar)
```

### Issue: Integration tests fail - "NetBox object not found"

**Solution**: Re-run the deployment script:

```bash
python tests/integration/netbox-deploy.py
```

**Check data was created**:

```bash
curl -H "Authorization: Token 0123456789abcdef0123456789abcdef01234567" \
  http://localhost:32768/api/dcim/sites/ | jq '.results | length'
# Should return > 0
```

### Issue: "ansible-test: command not found"

**Solution**: Install ansible-test:

```bash
pip install ansible-core
# Or
poetry install
```

### Issue: Black formatting fails

**Solution**: Auto-format the code:

```bash
black .
# Then review changes
git diff
```

### Issue: "Version X.X.X of the Python 'coverage' module is required"

**Error**: `FATAL: Version 7.10.7 of the Python "coverage" module is required. Version X.X.X was found.`

**Solution**: ansible-test is strict about coverage version. Install the exact version:

```bash
pip install 'coverage==7.10.7'
```

**Note**: The pyproject.toml has been updated to use this version.

### Issue: Coverage report not generated

**Solution**: Run tests with --coverage flag:

```bash
PYTHON_VERSION=$(python3 --version | grep -oP '\d+\.\d+')
ansible-test units -v --python "${PYTHON_VERSION}" --coverage
ansible-test coverage report  # Text report
ansible-test coverage html    # HTML report in tests/output/reports/
```

### Issue: Inventory tests fail with deepdiff errors

**Solution**: Install deepdiff:

```bash
pip install deepdiff
# Or
poetry install
```

### Issue: "Using locale 'C.UTF-8' instead of 'en_US.UTF-8'"

**Warning**: `Using locale "C.UTF-8" instead of "en_US.UTF-8". Tests which depend on the locale may behave unexpectedly.`

**Impact**: Safe to ignore for this collection - NetBox API tests are locale-independent.

**To eliminate the warning** (optional):

```bash
# Ubuntu/Debian - install en_US.UTF-8 locale
sudo apt-get install locales
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8

# Verify
locale -a | grep en_US
```

**Alternative**: Explicitly use C.UTF-8 (already set in venv/bin/activate):

```bash
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
```

---

## Test File Locations Reference

```
tests/
├── unit/
│   ├── module_utils/
│   │   └── netbox_utils/
│   │       └── test_netbox_module.py       # Main unit tests
│   └── inventory/
│       └── test_nb_inventory.py            # Inventory plugin tests
│
├── integration/
│   ├── netbox-deploy.py                    # Pre-populate test data
│   ├── targets/
│   │   ├── v4.3/
│   │   │   ├── tasks/                      # 91 module test playbooks
│   │   │   │   ├── netbox_device.yml
│   │   │   │   ├── netbox_site.yml
│   │   │   │   └── ...
│   │   │   └── meta/main.yml
│   │   ├── inventory-v4.3/
│   │   │   ├── runme.sh                    # Inventory test runner
│   │   │   ├── compare_inventory_json.py   # JSON comparison script
│   │   │   └── files/                      # Expected outputs
│   │   │       ├── 01-empty.json
│   │   │       ├── 02-hosts_true.json
│   │   │       └── ...
│   │   └── regression-v4.3/
│   │       └── tasks/                      # Regression test playbooks
│   └── netbox-docker/
│       └── v4.3/
│           └── docker-compose.override.yml # Docker config
│
└── output/                                 # Test results (gitignored)
    └── reports/                            # Coverage HTML reports
```

---

## Helpful Commands Cheat Sheet

```bash
# ALWAYS activate venv first!
source venv/bin/activate

# Detect Python version (for manual commands)
PYTHON_VERSION=$(python3 --version | grep -oP '\d+\.\d+')

# Quick formatting
black . && yamllint . && ansible-lint

# Quick unit test
pytest -vv tests/unit/

# Build collection
./hacking/build.sh

# Full local test (no Docker) - auto-detects Python version
./hacking/local-test.sh

# Quick test wrapper scripts
./quick-test.sh unit        # Unit tests only
./quick-test.sh format-fix  # Auto-format code
./quick-test.sh all         # All tests (no Docker)

# Run specific unit test
pytest -vv tests/unit/module_utils/netbox_utils/test_netbox_module.py::test_normalize_data_returns_correct_data

# Integration tests (requires NetBox Docker running)
./hacking/integration-test.sh v4.3  # All-in-one: build + deps + test

# Or run integration test manually (uses detected Python version)
ansible-test integration -v --python "${PYTHON_VERSION}" v4.3 --allow-destructive

# NetBox Docker management
./netbox-docker-helper.sh start v4.3   # Start NetBox
./netbox-docker-helper.sh populate     # Load test data
./netbox-docker-helper.sh stop         # Stop & cleanup

# Check test coverage
ansible-test units --coverage && ansible-test coverage report

# Update inventory test data
./hacking/update_test_inventories.sh

# Check NetBox Docker logs
docker logs -f netbox-docker-netbox-1

# Clean build artifacts
rm -rf netbox-netbox-*.tar.gz tests/output/
```

---

## Next Steps

1. **Start with unit tests**: `pytest -vv tests/unit/`
2. **Run sanity checks**: `./hacking/local-test.sh`
3. **Set up Docker for integration tests**: See "Integration Testing with Docker"
4. **Review CI configuration**: `.github/workflows/main.yml` to see what runs in CI

For questions or issues, see:

- [CONTRIBUTING.md](CONTRIBUTING.md) - Development guidelines
- [GitHub Issues](https://github.com/netbox-community/ansible_modules/issues)
- CI workflows: `.github/workflows/main.yml`

---

**Last Updated**: 2026-02-05
**Collection Version**: 3.22.0
**Supported NetBox Versions**: 4.0, 4.1, 4.2, 4.3, 4.4, 4.5
**Python Versions**: 3.11, 3.12, 3.13
