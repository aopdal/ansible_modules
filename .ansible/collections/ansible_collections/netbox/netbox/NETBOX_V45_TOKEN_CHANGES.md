# Summary of Changes for NetBox v4.5 v2 API Token Support

## Problem

NetBox v4.5 with netbox-docker 4.0.0+ creates v2 API tokens by default. These tokens:

- Cannot be pre-configured via `SUPERUSER_API_TOKEN` environment variable
- Must be provisioned via the `/api/users/tokens/provision/` API endpoint
- Use a different format: `nbt_<KEY>.<TOKEN>` instead of a simple 40-character hex string
- Require Bearer authentication instead of Token authentication

## Solution Overview

The solution provisions v2 API tokens dynamically after NetBox starts, both for local testing and CI/CD.

## Quick Start

**For detailed usage instructions, see [LOCAL_TESTING_GUIDE.md](LOCAL_TESTING_GUIDE.md#netbox-v45-and-v2-api-tokens)**

```bash
# Start NetBox v4.5 (auto-provisions token)
./netbox-docker-helper.sh start v4.5

# Populate test data
./netbox-docker-helper.sh populate

# Run tests
./hacking/integration-test.sh v4.5
```

## Files Created

### 1. `tests/netbox-docker/provision-token.sh` (NEW)

- **Purpose**: Provisions v2 API tokens via the NetBox API
- **Usage**: `./tests/netbox-docker/provision-token.sh`
- **Output**: `nbt_<KEY>.<TOKEN>` format
- **Features**:
  - Waits for NetBox to be ready before provisioning
  - Detects v1 vs v2 token format
  - Saves token to `/tmp/netbox-token.env` for sourcing
  - Outputs just the token on stdout for scripting

### 2. `tests/netbox-docker/v4.5/README.md` (NEW)

- Comprehensive documentation for v4.5 testing
- Explains v1 vs v2 token differences
- Provides usage examples for local and CI testing
- Includes troubleshooting guide

## Files Modified

### 1. `netbox-docker-helper.sh`

**Changes:**

- Auto-provisions v2 tokens for v4.5 after container startup
- Updated `populate` command to handle both v1 and v2 tokens
- Shows appropriate verification commands based on token type
- Updated help text to document v4.5 token behavior

**Key improvements:**

```bash
# For v4.5, automatically provisions token
if [ "$VERSION" = "v4.5" ]; then
    NETBOX_TOKEN=$("$SCRIPT_DIR/tests/netbox-docker/provision-token.sh")
    echo "export NETBOX_TOKEN=\"$NETBOX_TOKEN\""
fi

# populate command now auto-provisions if needed
if [ -z "${NETBOX_TOKEN:-}" ]; then
    NETBOX_TOKEN=$("$SCRIPT_DIR/tests/netbox-docker/provision-token.sh" 2>&1 | tail -n 1)
fi
```

### 2. `tests/netbox-docker/v4.5/docker-compose.override.yml`

**Changes:**

- Removed `SUPERUSER_API_TOKEN` (incompatible with v2 tokens)
- Added comment explaining token provisioning via API
- Kept `SUPERUSER_NAME` and `SUPERUSER_PASSWORD` for API provisioning

### 3. `tests/integration/netbox-deploy.py`

**Changes:**

- Detects v2 tokens (starting with `nbt_`)
- Adds logging for token type and NetBox version
- pynetbox automatically handles Bearer vs Token auth

**Code added:**

```python
# Check if this is a v2 token (nbt_ prefix) and configure accordingly
if nb_token.startswith("nbt_"):
    print(f"Using NetBox v2 API token (Bearer auth)")
else:
    print(f"Using NetBox v1 API token (Token auth)")
```

### 4. `.github/workflows/main.yml`

**Changes:**

- Added v4.5 to test matrix
- Added token provisioning step that runs only for v4.5
- Exports `NETBOX_TOKEN` to environment for subsequent steps

**New step:**

```yaml
- name: Provision v2 API Token for v4.5+
  if: matrix.VERSION == 'v4.5'
  run: |
    chmod +x ./tests/netbox-docker/provision-token.sh
    NETBOX_TOKEN=$(./tests/netbox-docker/provision-token.sh)
    echo "NETBOX_TOKEN=$NETBOX_TOKEN" >> $GITHUB_ENV
```

## How It Works

**For complete documentation, see [LOCAL_TESTING_GUIDE.md](LOCAL_TESTING_GUIDE.md#netbox-v45-and-v2-api-tokens)**

### Local Testing Workflow

```bash
# 1. Start NetBox
./netbox-docker-helper.sh start v4.5
# → Starts containers
# → Auto-provisions v2 token
# → Saves to /tmp/netbox-token.env

# 2. Load token (if needed)
source /tmp/netbox-token.env

# 3. Populate test data
./netbox-docker-helper.sh populate
# → Uses NETBOX_TOKEN from environment or provisions new one
# → Runs netbox-deploy.py with correct token

# 4. Run tests
ansible-test integration -v v4.5
# → Tests use token from environment or fall back to hardcoded value
```

### GitHub Actions Workflow

```yaml
1. Clone and start netbox-docker
2. Wait for NetBox to be available
3. Provision v2 API token (v4.5 only)
   → Runs provision-token.sh
   → Exports NETBOX_TOKEN to environment
4. Pre-populate NetBox
   → netbox-deploy.py reads NETBOX_TOKEN from environment
5. Run integration tests
   → Tests use NETBOX_TOKEN from environment
```

## Token Format Comparison

| Version            | Format          | Example                            | Auth Header                         |
|--------------------|-----------------|------------------------------------|------------------------------------|
| v1 (v4.0-v4.4)     | 40-char hex     | `0123456789abcdef...`              | `Authorization: Token <token>`     |
| v2 (v4.5+)         | `nbt_KEY.TOKEN` | `nbt_XWdV7GISgXjc.9sjhCYCr...`     | `Authorization: Bearer <token>`    |

**For troubleshooting and detailed testing instructions, see [LOCAL_TESTING_GUIDE.md](LOCAL_TESTING_GUIDE.md)**

## Testing the Solution

### Test locally

```bash
# Clean start
./netbox-docker-helper.sh stop
./netbox-docker-helper.sh start v4.5

# Check token was provisioned
cat /tmp/netbox-token.env

# Should see something like:
# export NETBOX_TOKEN="nbt_XWdV7GISgXjc.9sjhCYCrTlmNGWqQ7Vxv8J1uFFNUSWm3iokIwqg4"

# Test API access
source /tmp/netbox-token.env
curl -H "Authorization: Bearer $NETBOX_TOKEN" http://localhost:32768/api/dcim/sites/
```

### Test in GitHub Actions

- Push changes to a branch
- Open a PR or trigger workflow_dispatch
- Check the "Provision v2 API Token for v4.5+" step in the workflow run
- Verify integration tests pass for v4.5

## Backwards Compatibility

- **v4.0-v4.4**: No changes needed, continue using hardcoded v1 tokens
- **v4.5**: Uses dynamic v2 token provisioning
- Both old and new workflows supported simultaneously

## Future Considerations

### Potential improvements

1. **Update test task files**: Currently test files have hardcoded tokens. Could update to use environment variables:

   ```yaml
   netbox_token: "{{ lookup('env', 'NETBOX_TOKEN') | default('0123456789abcdef...') }}"
   ```

2. **Token caching**: Save provisioned tokens to avoid re-provisioning on each test run

3. **Token validation**: Add a step to validate token before running tests

4. **Multi-version support**: Extend to support multiple NetBox instances with different tokens

## Key Benefits

✅ Works in both local and CI environments  
✅ No manual token management required  
✅ Backwards compatible with older NetBox versions  
✅ Clear documentation and error messages  
✅ Minimal changes to existing test infrastructure  

## Notes for Users

- The `NETBOX_TOKEN` environment variable is now the source of truth for all tests
- For v4.5+, tokens are generated dynamically each time NetBox starts
- The token is saved to `/tmp/netbox-token.env` for easy sourcing
- pynetbox automatically detects v2 tokens and uses Bearer authentication
- No changes needed to existing test task files (they still work with environment override)
