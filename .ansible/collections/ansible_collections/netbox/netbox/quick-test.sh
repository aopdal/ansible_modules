#!/usr/bin/env bash
#
# Quick Test Script for NetBox Ansible Collection
# Usage: ./quick-test.sh [unit|sanity|format|all]
#

set -euo pipefail

COMMAND="${1:-help}"

show_help() {
    cat << EOF
Quick Test Script for NetBox Ansible Collection

Usage: ./quick-test.sh [COMMAND]

Commands:
  unit        Run unit tests only (fast, no Docker needed)
  sanity      Run sanity tests (code quality checks)
  format      Run code formatting (black, yamllint)
  format-fix  Auto-fix formatting issues
  all         Run unit + sanity + formatting checks
  help        Show this help message

Examples:
  ./quick-test.sh unit        # Run just unit tests
  ./quick-test.sh format-fix  # Auto-format code with black
  ./quick-test.sh all         # Run complete test suite (no Docker)

For integration tests (requires NetBox Docker), see: LOCAL_TESTING_GUIDE.md
EOF
}

run_unit_tests() {
    echo "================================"
    echo "Running Unit Tests (pytest)..."
    echo "================================"

    if command -v pytest &> /dev/null; then
        pytest -vv tests/unit/
    else
        echo "ERROR: pytest not found. Install with: pip install pytest pytest-mock"
        exit 1
    fi
}

run_sanity_tests() {
    echo "================================"
    echo "Running Sanity Tests..."
    echo "================================"

    # Use the existing local-test.sh which handles collection installation
    ./hacking/local-test.sh
}

run_format_check() {
    echo "================================"
    echo "Checking Code Formatting..."
    echo "================================"

    ERRORS=0

    # Check black
    if command -v black &> /dev/null; then
        echo "Checking Python formatting (black)..."
        if ! black --check .; then
            echo "ERROR: Black formatting issues found. Run: ./quick-test.sh format-fix"
            ERRORS=1
        else
            echo "✓ Black formatting OK"
        fi
    else
        echo "WARNING: black not found. Install with: pip install black"
    fi

    # Check yamllint
    if command -v yamllint &> /dev/null; then
        echo "Checking YAML formatting..."
        if ! yamllint .; then
            echo "ERROR: YAML linting issues found"
            ERRORS=1
        else
            echo "✓ YAML linting OK"
        fi
    else
        echo "WARNING: yamllint not found. Install with: pip install yamllint"
    fi

    # Check ansible-lint
    if command -v ansible-lint &> /dev/null; then
        echo "Checking Ansible formatting..."
        if ! ansible-lint; then
            echo "ERROR: Ansible linting issues found"
            ERRORS=1
        else
            echo "✓ Ansible linting OK"
        fi
    else
        echo "WARNING: ansible-lint not found. Install with: pip install ansible-lint"
    fi

    if [ $ERRORS -ne 0 ]; then
        exit 1
    fi
}

run_format_fix() {
    echo "================================"
    echo "Auto-fixing Code Formatting..."
    echo "================================"

    if command -v black &> /dev/null; then
        echo "Running black formatter..."
        black .
        echo "✓ Black formatting complete"
    else
        echo "ERROR: black not found. Install with: pip install black"
        exit 1
    fi

    echo ""
    echo "Note: yamllint and ansible-lint issues may need manual fixes"
}

run_all() {
    echo "================================"
    echo "Running Full Test Suite..."
    echo "================================"

    run_format_check
    echo ""
    run_unit_tests
    echo ""
    run_sanity_tests

    echo ""
    echo "================================"
    echo "✓ All tests passed!"
    echo "================================"
}

# Main script logic
case "$COMMAND" in
    unit)
        run_unit_tests
        ;;
    sanity)
        run_sanity_tests
        ;;
    format)
        run_format_check
        ;;
    format-fix)
        run_format_fix
        ;;
    all)
        run_all
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "ERROR: Unknown command: $COMMAND"
        echo ""
        show_help
        exit 1
        ;;
esac
