#!/usr/bin/env bash
#
# Provision NetBox v2 API Token
# This script creates a v2 API token and outputs it in the required format
#

set -euo pipefail

NETBOX_URL="${NETBOX_URL:-http://localhost:32768}"
NETBOX_USERNAME="${NETBOX_USERNAME:-admin}"
NETBOX_PASSWORD="${NETBOX_PASSWORD:-admin123456}"
MAX_RETRIES="${MAX_RETRIES:-30}"
RETRY_DELAY="${RETRY_DELAY:-5}"

# Wait for NetBox to be ready
echo "Waiting for NetBox to be ready at $NETBOX_URL..." >&2
for i in $(seq 1 $MAX_RETRIES); do
    if curl -s -o /dev/null -w "%{http_code}" "$NETBOX_URL/login/" | grep -q "200"; then
        echo "✓ NetBox is ready" >&2
        break
    fi
    if [ $i -eq $MAX_RETRIES ]; then
        echo "ERROR: NetBox did not become ready in time" >&2
        exit 1
    fi
    echo "Waiting... ($i/$MAX_RETRIES)" >&2
    sleep $RETRY_DELAY
done

# Additional wait for NetBox to be fully initialized
echo "Waiting for NetBox initialization to complete..." >&2
sleep 10

# Provision the token
echo "Provisioning v2 API token..." >&2
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    "$NETBOX_URL/api/users/tokens/provision/" \
    --data "{\"username\": \"$NETBOX_USERNAME\", \"password\": \"$NETBOX_PASSWORD\"}")

# Check if the response is valid JSON
if ! echo "$RESPONSE" | jq . > /dev/null 2>&1; then
    echo "ERROR: Failed to provision token. Response was:" >&2
    echo "$RESPONSE" >&2
    exit 1
fi

# Check if we got an error
if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    echo "ERROR: Failed to provision token:" >&2
    echo "$RESPONSE" | jq -r '.error' >&2
    exit 1
fi

# Extract key and token
KEY=$(echo "$RESPONSE" | jq -r '.key')
TOKEN=$(echo "$RESPONSE" | jq -r '.token')
VERSION=$(echo "$RESPONSE" | jq -r '.version')

if [ -z "$KEY" ] || [ "$KEY" = "null" ] || [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "ERROR: Failed to extract key or token from response:" >&2
    echo "$RESPONSE" | jq . >&2
    exit 1
fi

# Check version
if [ "$VERSION" = "2" ]; then
    # v2 token format
    FULL_TOKEN="nbt_${KEY}.${TOKEN}"
    echo "" >&2
    echo "✓ Successfully provisioned v2 API token" >&2
    echo "" >&2
    echo "Token details:" >&2
    echo "  Key:     $KEY" >&2
    echo "  Token:   $TOKEN" >&2
    echo "  Version: $VERSION" >&2
    echo "" >&2
    echo "Full token (use this): $FULL_TOKEN" >&2
    echo "" >&2
    
    # Export as environment variable
    export NETBOX_TOKEN="$FULL_TOKEN"
    
    # Save to file for sourcing
    TOKEN_FILE="${TOKEN_FILE:-/tmp/netbox-token.env}"
    echo "export NETBOX_TOKEN=\"$FULL_TOKEN\"" > "$TOKEN_FILE"
    echo "✓ Token saved to $TOKEN_FILE" >&2
    echo "  Source it with: source $TOKEN_FILE" >&2
    echo "" >&2
    
    # Output just the token on stdout for scripting
    echo "$FULL_TOKEN"
else
    # v1 token format (fallback)
    echo "✓ Successfully provisioned v1 API token" >&2
    echo "Token: $KEY" >&2
    
    export NETBOX_TOKEN="$KEY"
    TOKEN_FILE="${TOKEN_FILE:-/tmp/netbox-token.env}"
    echo "export NETBOX_TOKEN=\"$KEY\"" > "$TOKEN_FILE"
    echo "$KEY"
fi
