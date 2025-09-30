#!/usr/bin/env bash
set -euo pipefail

# Home Assistant bootc image smoke test
# Usage: ./tests/smoke-test.sh [image-name]
# Example: ./tests/smoke-test.sh homeassistant-bootc:dev

IMAGE_NAME="${1:-homeassistant-bootc:dev}"
CONTAINER_NAME="homeassistant-smoke-test"

echo "[smoke-test] Starting smoke test for image: $IMAGE_NAME"

# Clean up any existing test container
cleanup() {
    echo "[smoke-test] Cleaning up test container..."
    podman rm -f "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

# Test 1: Verify bootc metadata
echo "[smoke-test] Test 1: Verifying bootc metadata..."
if ! podman run --rm --privileged "$IMAGE_NAME" bootc status; then
    echo "[smoke-test] FAIL: bootc status check failed" >&2
    exit 1
fi
echo "[smoke-test] PASS: bootc metadata verified"

# Test 2: Check Home Assistant service status
echo "[smoke-test] Test 2: Checking Home Assistant service..."
if ! podman run --rm "$IMAGE_NAME" /usr/bin/systemctl is-enabled home-assistant.service; then
    echo "[smoke-test] FAIL: Home Assistant service not enabled" >&2
    exit 1
fi
echo "[smoke-test] PASS: Home Assistant service is enabled"

# Test 3: Verify Home Assistant configuration
echo "[smoke-test] Test 3: Verifying Home Assistant configuration..."
if ! podman run --rm "$IMAGE_NAME" test -f /var/lib/home-assistant/configuration.yaml; then
    echo "[smoke-test] FAIL: Home Assistant configuration missing" >&2
    exit 1
fi
echo "[smoke-test] PASS: Home Assistant configuration exists"

# Test 4: Check environment file
echo "[smoke-test] Test 4: Checking environment file..."
if ! podman run --rm "$IMAGE_NAME" test -f /etc/home-assistant/home-assistant.env; then
    echo "[smoke-test] FAIL: Home Assistant environment file missing" >&2
    exit 1
fi
echo "[smoke-test] PASS: Home Assistant environment file exists"

# Test 5: Verify Greenboot health scripts
echo "[smoke-test] Test 5: Verifying Greenboot health scripts..."
if ! podman run --rm "$IMAGE_NAME" test -x /etc/greenboot/check/required.d/10-home-assistant.sh; then
    echo "[smoke-test] FAIL: Required Greenboot health script missing or not executable" >&2
    exit 1
fi
if ! podman run --rm "$IMAGE_NAME" test -x /etc/greenboot/check/wants.d/30-podman-network.sh; then
    echo "[smoke-test] FAIL: Optional Greenboot health script missing or not executable" >&2
    exit 1
fi
echo "[smoke-test] PASS: Greenboot health scripts verified"

# Test 6: Check systemd unit file
echo "[smoke-test] Test 6: Checking systemd unit file..."
if ! podman run --rm "$IMAGE_NAME" test -f /usr/lib/systemd/system/home-assistant.service; then
    echo "[smoke-test] FAIL: Home Assistant systemd unit missing" >&2
    exit 1
fi
echo "[smoke-test] PASS: Home Assistant systemd unit exists"

# Test 7: Verify linux-system-roles installation
echo "[smoke-test] Test 7: Verifying linux-system-roles installation..."
if ! podman run --rm "$IMAGE_NAME" test -d /usr/share/ansible/collections/ansible_collections/fedora/linux_system_roles; then
    echo "[smoke-test] FAIL: linux-system-roles not installed" >&2
    exit 1
fi
echo "[smoke-test] PASS: linux-system-roles verified"

echo "[smoke-test] All smoke tests passed! ✅"
echo "[smoke-test] Image $IMAGE_NAME is ready for deployment"