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
<<<<<<< HEAD
  v4.1 tests → NetBox v4.1 image (netbox-docker 3.0.2)
  v4.2 tests → NetBox v4.2 image (netbox-docker 3.2.1)
  v4.3 tests → NetBox v4.3 image (netbox-docker 3.3.0)
  v4.4 tests → NetBox v4.4 image (netbox-docker 3.4.2)
  v4.5 tests → NetBox v4.5 image (netbox-docker release)
=======
  v4.1 tests → NetBox v4.1 image
  v4.2 tests → NetBox v4.2 image
  v4.3 tests → NetBox v4.3 image
  v4.4 tests → NetBox v4.4 image
  v4.5 tests → NetBox v4.5 image (latest)
>>>>>>> 68d4b64 (Add local testing infrastructure for inventory and regression tests)

Integration Test Workflow:
  1. ./netbox-docker-helper.sh start v4.5
  2. Wait for healthy status (~2-3 minutes)
<<<<<<< HEAD
  3. For v4.5: Token is auto-provisioned (v2 API token)
     For v4.0-v4.4: Uses predefined token from docker-compose
  4. ./netbox-docker-helper.sh populate
  5. Run your tests: ansible-test integration -v v4.5
  6. ./netbox-docker-helper.sh stop

Note: NetBox v4.5+ uses v2 API tokens (nbt_KEY.TOKEN format)
      which are automatically provisioned via the API.
      See tests/netbox-docker/v4.5/README.md for details.
=======
  3. ./netbox-docker-helper.sh populate
  4. Run your tests: ansible-test integration -v v4.5
  5. ./netbox-docker-helper.sh stop
>>>>>>> 68d4b64 (Add local testing infrastructure for inventory and regression tests)
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
<<<<<<< HEAD
    local VERSION="${1:-$DEFAULT_VERSION}"
    
    # Map NetBox versions to netbox-docker versions
    local DOCKER_VERSION="release"
    case "$VERSION" in
        v4.1)
            DOCKER_VERSION="3.0.2"
            ;;
        v4.2)
            DOCKER_VERSION="3.2.1"
            ;;
        v4.3)
            DOCKER_VERSION="3.3.0"
            ;;
        v4.4)
            DOCKER_VERSION="3.4.2"
            ;;
        v4.5)
            DOCKER_VERSION="release"
            ;;
    esac
    
    if [ ! -d "$NETBOX_DOCKER_DIR" ]; then
        echo "Cloning netbox-docker..."
        git clone https://github.com/netbox-community/netbox-docker.git "$NETBOX_DOCKER_DIR"
    else
        echo "Using existing netbox-docker at $NETBOX_DOCKER_DIR"
    fi
    
    cd "$NETBOX_DOCKER_DIR"
    
    # Fetch all branches and tags
    echo "Fetching netbox-docker repository..."
    git fetch origin 2>/dev/null || true
    
    # Checkout the appropriate version
    echo "Checking out netbox-docker $DOCKER_VERSION for NetBox $VERSION..."
    git checkout "$DOCKER_VERSION" 2>/dev/null || {
        echo "ERROR: Failed to checkout netbox-docker $DOCKER_VERSION"
        exit 1
    }
    
    # Pull latest if on a branch
    if [ "$DOCKER_VERSION" = "release" ]; then
        git pull origin release 2>/dev/null || true
    fi
    
    cd - > /dev/null
=======
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
>>>>>>> 68d4b64 (Add local testing infrastructure for inventory and regression tests)
}

start_netbox() {
    local VERSION="${1:-$DEFAULT_VERSION}"

    check_docker
<<<<<<< HEAD
    clone_netbox_docker "$VERSION"
=======
    clone_netbox_docker
>>>>>>> 68d4b64 (Add local testing infrastructure for inventory and regression tests)

    echo "================================"
    echo "Starting NetBox $VERSION"
    echo "================================"

    # Check if override file exists
    local OVERRIDE_FILE="$SCRIPT_DIR/tests/netbox-docker/$VERSION/docker-compose.override.yml"
    if [ ! -f "$OVERRIDE_FILE" ]; then
        echo "ERROR: Override file not found: $OVERRIDE_FILE"
<<<<<<< HEAD
        echo "Available versions: v4.0, v4.1, v4.2, v4.3, v4.4, v4.5"
=======
        echo "Available versions: v4.0, v4.1, v4.2, v4.3"
>>>>>>> 68d4b64 (Add local testing infrastructure for inventory and regression tests)
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
<<<<<<< HEAD
=======
    echo "API Token: 0123456789abcdef0123456789abcdef01234567"
>>>>>>> 68d4b64 (Add local testing infrastructure for inventory and regression tests)
    echo ""
    echo "Wait for healthy status (~2-3 minutes):"
    echo "  ./netbox-docker-helper.sh logs"
    echo "  Look for: 'Listening at: http://0.0.0.0:8080'"
    echo ""
<<<<<<< HEAD
    
    # For v4.5+, provision v2 API token
    if [ "$VERSION" = "v4.5" ]; then
        echo "Provisioning v2 API token for NetBox $VERSION..."
        echo ""
        
        # Wait a bit for NetBox to be fully ready
        sleep 5
        
        # Run the provision script
        if [ -f "$SCRIPT_DIR/tests/netbox-docker/provision-token.sh" ]; then
            NETBOX_TOKEN=$("$SCRIPT_DIR/tests/netbox-docker/provision-token.sh")
            
            if [ $? -eq 0 ]; then
                echo "Then populate test data:"
                echo "  ./netbox-docker-helper.sh populate"
                echo ""
                echo "Or run tests directly:"
                echo "  export NETBOX_TOKEN=\"$NETBOX_TOKEN\""
                echo "  ansible-test integration -v $VERSION"
            else
                echo "WARNING: Token provisioning failed. You may need to provision manually."
                echo "Run: ./tests/netbox-docker/provision-token.sh"
            fi
        else
            echo "Then provision API token:"
            echo "  ./tests/netbox-docker/provision-token.sh"
            echo ""
            echo "Then populate test data:"
            echo "  ./netbox-docker-helper.sh populate"
        fi
    else
        echo "API Token: 0123456789abcdef0123456789abcdef01234567"
        echo ""
        echo "Then populate test data:"
        echo "  ./netbox-docker-helper.sh populate"
    fi
=======
    echo "Then populate test data:"
    echo "  ./netbox-docker-helper.sh populate"
>>>>>>> 68d4b64 (Add local testing infrastructure for inventory and regression tests)
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
<<<<<<< HEAD
    
    # Clean up token files since they won't be valid for the next instance
    if [ -f "/tmp/netbox-token.env" ]; then
        rm -f /tmp/netbox-token.env
        echo "✓ Cleaned up token file"
    fi
    if [ -f "/tmp/.netbox_test_token" ]; then
        rm -f /tmp/.netbox_test_token
        echo "✓ Cleaned up test token file"
    fi
=======
>>>>>>> 68d4b64 (Add local testing infrastructure for inventory and regression tests)
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
<<<<<<< HEAD
    
    # Detect NetBox version from login page (doesn't require auth)
    NETBOX_VERSION=$(curl -s http://localhost:32768/login/ | grep -oP 'data-netbox-version="\K[^"]+' | cut -d'-' -f1 2>/dev/null || echo "unknown")
    echo "Detected NetBox version: $NETBOX_VERSION"
    
    # Determine if we need v2 token (4.5+) or v1 token (4.4 and earlier)
    NEEDS_V2_TOKEN=false
    if [[ "$NETBOX_VERSION" == 4.5* ]] || [[ "$NETBOX_VERSION" == 4.[6-9]* ]] || [[ "$NETBOX_VERSION" == [5-9].* ]]; then
        NEEDS_V2_TOKEN=true
    fi
    
    # Check if we have a token already
    if [ -z "${NETBOX_TOKEN:-}" ]; then
        # Try to load from saved file first
        if [ -f "/tmp/netbox-token.env" ]; then
            source /tmp/netbox-token.env
        fi
    fi
    
    # Check if loaded token format matches what we need
    if [ -n "${NETBOX_TOKEN:-}" ]; then
        if [[ "$NETBOX_TOKEN" == nbt_* ]] && [ "$NEEDS_V2_TOKEN" = false ]; then
            echo "Warning: Found v2 token but NetBox $NETBOX_VERSION needs v1 token"
            unset NETBOX_TOKEN
            rm -f /tmp/netbox-token.env
        elif [[ "$NETBOX_TOKEN" != nbt_* ]] && [ "$NEEDS_V2_TOKEN" = true ]; then
            echo "Warning: Found v1 token but NetBox $NETBOX_VERSION needs v2 token"
            unset NETBOX_TOKEN
            rm -f /tmp/netbox-token.env
        else
            # Validate that the token is still valid for this NetBox instance
            if [ "$NEEDS_V2_TOKEN" = true ]; then
                # Test v2 token with Bearer auth
                HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
                    -H "Authorization: Bearer $NETBOX_TOKEN" \
                    http://localhost:32768/api/dcim/sites/ 2>/dev/null)
            else
                # Test v1 token with Token auth
                HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
                    -H "Authorization: Token $NETBOX_TOKEN" \
                    http://localhost:32768/api/dcim/sites/ 2>/dev/null)
            fi
            
            if [ "$HTTP_CODE" != "200" ]; then
                echo "Warning: Existing token is no longer valid (HTTP $HTTP_CODE), will provision new token"
                unset NETBOX_TOKEN
                rm -f /tmp/netbox-token.env
            else
                echo "✓ Existing token is valid"
            fi
        fi
    fi
    
    # If still no token, provision the appropriate one
    if [ -z "${NETBOX_TOKEN:-}" ]; then
        if [ "$NEEDS_V2_TOKEN" = true ]; then
            echo "NetBox 4.5+ detected, provisioning v2 API token..."
            if [ -f "$SCRIPT_DIR/tests/netbox-docker/provision-token.sh" ]; then
                NETBOX_TOKEN=$("$SCRIPT_DIR/tests/netbox-docker/provision-token.sh")
                export NETBOX_TOKEN
            else
                echo "ERROR: provision-token.sh not found"
                exit 1
            fi
        else
            # For NetBox 4.4 and earlier, use the pre-configured v1 token
            echo "NetBox 4.4 or earlier detected, using pre-configured v1 token"
            export NETBOX_TOKEN="0123456789abcdef0123456789abcdef01234567"
        fi
    fi

    echo "Running netbox-deploy.py with token: ${NETBOX_TOKEN:0:20}..."
=======

    echo "Running netbox-deploy.py..."
>>>>>>> 68d4b64 (Add local testing infrastructure for inventory and regression tests)
    python tests/integration/netbox-deploy.py

    echo ""
    echo "✓ Test data populated successfully"
    echo ""
<<<<<<< HEAD
    
    # Show appropriate verification command based on token format
    if [[ "$NETBOX_TOKEN" == nbt_* ]]; then
        echo "Verify data (v2 token):"
        echo "  curl -H 'Authorization: Bearer $NETBOX_TOKEN' http://localhost:32768/api/dcim/sites/ | jq '.count'"
    else
        echo "Verify data (v1 token):"
        echo "  curl -H 'Authorization: Token $NETBOX_TOKEN' http://localhost:32768/api/dcim/sites/ | jq '.count'"
    fi
=======
    echo "Verify data:"
    echo "  curl -H 'Authorization: Token 0123456789abcdef0123456789abcdef01234567' http://localhost:32768/api/dcim/sites/ | jq '.count'"
>>>>>>> 68d4b64 (Add local testing infrastructure for inventory and regression tests)
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
