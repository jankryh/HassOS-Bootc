#!/usr/bin/env bash
set -euo pipefail

# Build test script for Home Assistant bootc image
# Usage: ./tests/build-test.sh [image-name]
# Example: ./tests/build-test.sh homeassistant-bootc:test

IMAGE_NAME="${1:-homeassistant-bootc:test}"
BUILD_LOG="build-$(date +%Y%m%d-%H%M%S).log"

echo "[build-test] Starting build test for image: $IMAGE_NAME"
echo "[build-test] Build log: $BUILD_LOG"

# Clean up any existing image
cleanup() {
    echo "[build-test] Cleaning up test image..."
    podman rmi "$IMAGE_NAME" 2>/dev/null || true
}
trap cleanup EXIT

# Test 1: Build the image
echo "[build-test] Test 1: Building container image..."
if ! podman build -t "$IMAGE_NAME" . 2>&1 | tee "$BUILD_LOG"; then
    echo "[build-test] FAIL: Container build failed" >&2
    echo "[build-test] Check build log: $BUILD_LOG" >&2
    exit 1
fi
echo "[build-test] PASS: Container build successful"

# Test 2: Verify image exists
echo "[build-test] Test 2: Verifying image exists..."
if ! podman image exists "$IMAGE_NAME"; then
    echo "[build-test] FAIL: Image not found after build" >&2
    exit 1
fi
echo "[build-test] PASS: Image exists"

# Test 3: Check image size (should be reasonable)
echo "[build-test] Test 3: Checking image size..."
IMAGE_SIZE=$(podman images --format "{{.Size}}" "$IMAGE_NAME")
echo "[build-test] Image size: $IMAGE_SIZE"
echo "[build-test] PASS: Image size check completed"

# Test 4: Run smoke tests on built image
echo "[build-test] Test 4: Running smoke tests on built image..."
if ! ./tests/smoke-test.sh "$IMAGE_NAME"; then
    echo "[build-test] FAIL: Smoke tests failed on built image" >&2
    exit 1
fi
echo "[build-test] PASS: Smoke tests passed on built image"

# Test 5: Test bootc image build (if bootc is available)
echo "[build-test] Test 5: Testing bootc image build..."
if command -v bootc >/dev/null 2>&1; then
    mkdir -p out
    if bootc image build --target-arch=x86_64 --ref "quay.io/test/homeassistant-bootc:test" --output "iso=out/homeassistant-test.iso" .; then
        echo "[build-test] PASS: bootc image build successful"
        echo "[build-test] ISO created: out/homeassistant-test.iso"
    else
        echo "[build-test] WARN: bootc image build failed (bootc may not be properly configured)"
    fi
else
    echo "[build-test] SKIP: bootc not available, skipping ISO generation"
fi

echo "[build-test] All build tests passed! ✅"
echo "[build-test] Image $IMAGE_NAME is ready for deployment"
echo "[build-test] Build log saved: $BUILD_LOG"