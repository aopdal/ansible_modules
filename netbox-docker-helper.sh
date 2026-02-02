#!/usr/bin/env bash
#
# NetBox Docker Helper for Integration Tests
# Usage: ./netbox-docker-helper.sh [start|stop|restart|logs|status] [VERSION]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NETBOX_DOCKER_DIR="${NETBOX_DOCKER_DIR:-/tmp/netbox-docker}"
DEFAULT_VERSION="v4.5"

show_help() {
    cat << EOF
NetBox Docker Helper for Integration Tests

Usage: ./netbox-docker-helper.sh COMMAND [VERSION]

Commands:
  start [VERSION]    Start NetBox Docker (default: v4.5)
  stop               Stop and remove NetBox Docker containers
  restart [VERSION]  Restart NetBox Docker
  logs               Follow NetBox logs
  status             Show running NetBox containers
  populate           Populate test data (run after start)
  help               Show this help

Versions:
  v4.0, v4.1, v4.2, v4.3, v4.4, v4.5 (default: v4.5)

Examples:
  ./netbox-docker-helper.sh start v4.5     # Start NetBox v4.5
  ./netbox-docker-helper.sh populate       # Load test data
  ./netbox-docker-helper.sh logs           # Follow logs
  ./netbox-docker-helper.sh stop           # Stop containers

Test Version Mapping:
  v4.0 tests → NetBox v4.0 image
  v4.1 tests → NetBox v4.1 image
  v4.2 tests → NetBox v4.2 image
  v4.3 tests → NetBox v4.3 image
  v4.4 tests → NetBox v4.4 image
  v4.5 tests → NetBox v4.5 image (latest)

Integration Test Workflow:
  1. ./netbox-docker-helper.sh start v4.5
  2. Wait for healthy status (~2-3 minutes)
  3. ./netbox-docker-helper.sh populate
  4. Run your tests: ansible-test integration -v v4.5
  5. ./netbox-docker-helper.sh stop
EOF
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "ERROR: docker not found. Please install Docker first."
        exit 1
    fi

    # Detect docker-compose v1 or v2
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    elif docker compose version &> /dev/null; then
        DOCKER_COMPOSE="docker compose"
    else
        echo "ERROR: docker-compose or docker compose not found."
        echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi

    echo "Using: $DOCKER_COMPOSE"
}

clone_netbox_docker() {
    if [ ! -d "$NETBOX_DOCKER_DIR" ]; then
        echo "Cloning netbox-docker (release branch)..."
        git clone --branch release --single-branch https://github.com/netbox-community/netbox-docker.git "$NETBOX_DOCKER_DIR"
    else
        echo "Using existing netbox-docker at $NETBOX_DOCKER_DIR"
        cd "$NETBOX_DOCKER_DIR"
        echo "Pulling latest changes from release branch..."
        git fetch origin release 2>/dev/null || true
        git checkout release 2>/dev/null || true
        git pull origin release 2>/dev/null || true
        cd - > /dev/null
    fi
}

start_netbox() {
    local VERSION="${1:-$DEFAULT_VERSION}"

    check_docker
    clone_netbox_docker

    echo "================================"
    echo "Starting NetBox $VERSION"
    echo "================================"

    # Check if override file exists
    local OVERRIDE_FILE="$SCRIPT_DIR/tests/netbox-docker/$VERSION/docker-compose.override.yml"
    if [ ! -f "$OVERRIDE_FILE" ]; then
        echo "ERROR: Override file not found: $OVERRIDE_FILE"
        echo "Available versions: v4.0, v4.1, v4.2, v4.3"
        exit 1
    fi

    cd "$NETBOX_DOCKER_DIR"

    # Copy override file
    cp "$OVERRIDE_FILE" docker-compose.override.yml
    echo "✓ Copied override config for $VERSION"

    # Set version and pull
    export VERSION=$VERSION
    echo "Pulling NetBox $VERSION images..."
    $DOCKER_COMPOSE pull

    # Start containers
    echo "Starting containers..."
    $DOCKER_COMPOSE up -d

    echo ""
    echo "================================"
    echo "NetBox $VERSION is starting..."
    echo "================================"
    echo ""
    echo "Available at: http://localhost:32768"
    echo "Admin credentials: admin / admin123456"
    echo "API Token: 0123456789abcdef0123456789abcdef01234567"
    echo ""
    echo "Wait for healthy status (~2-3 minutes):"
    echo "  ./netbox-docker-helper.sh logs"
    echo "  Look for: 'Listening at: http://0.0.0.0:8080'"
    echo ""
    echo "Then populate test data:"
    echo "  ./netbox-docker-helper.sh populate"
    echo ""
}

stop_netbox() {
    if [ ! -d "$NETBOX_DOCKER_DIR" ]; then
        echo "NetBox Docker not found at $NETBOX_DOCKER_DIR"
        echo "Nothing to stop."
        return 0
    fi

    check_docker
    cd "$NETBOX_DOCKER_DIR"

    echo "Stopping NetBox containers..."
    $DOCKER_COMPOSE down -v
    echo "✓ NetBox stopped and volumes removed"
}

restart_netbox() {
    local VERSION="${1:-$DEFAULT_VERSION}"
    stop_netbox
    start_netbox "$VERSION"
}

show_logs() {
    if [ ! -d "$NETBOX_DOCKER_DIR" ]; then
        echo "ERROR: NetBox Docker not found at $NETBOX_DOCKER_DIR"
        exit 1
    fi

    check_docker
    cd "$NETBOX_DOCKER_DIR"
    echo "Following NetBox logs (Ctrl+C to exit)..."
    echo "Wait for: 'Listening at: http://0.0.0.0:8080'"
    echo ""
    $DOCKER_COMPOSE logs -f netbox
}

show_status() {
    echo "NetBox Docker Status:"
    echo ""
    docker ps --filter "name=netbox" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""

    # Check if NetBox is responding
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:32768/api/ | grep -q "200"; then
        echo "✓ NetBox API is responding at http://localhost:32768/api/"
    else
        echo "✗ NetBox API is not responding yet"
        echo "  Check logs: ./netbox-docker-helper.sh logs"
    fi
}

populate_data() {
    echo "================================"
    echo "Populating NetBox Test Data"
    echo "================================"

    # Check if NetBox is running
    if ! curl -s -o /dev/null http://localhost:32768/api/; then
        echo "ERROR: NetBox is not running or not ready"
        echo "Start NetBox first: ./netbox-docker-helper.sh start"
        exit 1
    fi

    cd "$SCRIPT_DIR"

    # Activate venv if it exists
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    fi

    echo "Running netbox-deploy.py..."
    python tests/integration/netbox-deploy.py

    echo ""
    echo "✓ Test data populated successfully"
    echo ""
    echo "Verify data:"
    echo "  curl -H 'Authorization: Token 0123456789abcdef0123456789abcdef01234567' http://localhost:32768/api/dcim/sites/ | jq '.count'"
    echo ""
    echo "Now run your integration tests!"
}

# Main script logic
COMMAND="${1:-help}"
VERSION="${2:-$DEFAULT_VERSION}"

case "$COMMAND" in
    start)
        start_netbox "$VERSION"
        ;;
    stop)
        stop_netbox
        ;;
    restart)
        restart_netbox "$VERSION"
        ;;
    logs)
        show_logs
        ;;
    status)
        show_status
        ;;
    populate)
        populate_data
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
