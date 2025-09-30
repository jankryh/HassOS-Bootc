# HassOS-Bootc Makefile
# Provides common build, test, and validation targets for HassOS-Bootc

.PHONY: help build test validate clean generate-bindep build-test smoke-test validate-ansible

# Default target
help:
	@echo "HassOS-Bootc - Available targets:"
	@echo ""
	@echo "Build targets:"
	@echo "  build              Build the container image"
	@echo "  generate-bindep    Generate dependency hints"
	@echo ""
	@echo "Image generation targets:"
	@echo "  qcow2              Generate QCOW2 image for VMs"
	@echo "  iso                Generate ISO image for bare-metal"
	@echo "  iso-arm64          Generate ARM64 ISO for Raspberry Pi"
	@echo "  images             Generate all image formats"
	@echo ""
	@echo "Test targets:"
	@echo "  test               Run all tests"
	@echo "  build-test         Build and test the image"
	@echo "  smoke-test         Run smoke tests on built image"
	@echo "  validate-ansible   Validate Ansible configuration"
	@echo ""
	@echo "Utility targets:"
	@echo "  clean              Clean up build artifacts"
	@echo "  validate           Run all validation checks"
	@echo ""
	@echo "Examples:"
	@echo "  make build IMAGE_NAME=hassos-bootc:dev"
	@echo "  make test IMAGE_NAME=hassos-bootc:test"
	@echo "  make qcow2          # Generate VM image"
	@echo "  make iso            # Generate bare-metal ISO"

# Configuration
IMAGE_NAME ?= hassos-bootc:dev
BUILD_LOG ?= build-$(shell date +%Y%m%d-%H%M%S).log

# Build targets
build:
	@echo "[make] Building container image: $(IMAGE_NAME)"
	podman build -t $(IMAGE_NAME) .

generate-bindep:
	@echo "[make] Generating dependency hints..."
	./build/generate-bindep.sh > bindep.txt
	@echo "[make] Generated bindep.txt with $$(wc -l < bindep.txt) packages"

# Test targets
test: build-test validate-ansible
	@echo "[make] All tests completed successfully"

build-test:
	@echo "[make] Running build test for image: $(IMAGE_NAME)"
	./tests/build-test.sh $(IMAGE_NAME)

smoke-test:
	@echo "[make] Running smoke test for image: $(IMAGE_NAME)"
	./tests/smoke-test.sh $(IMAGE_NAME)

validate-ansible:
	@echo "[make] Validating Ansible configuration..."
	./tests/validate-ansible.sh

# Validation target
validate: validate-ansible
	@echo "[make] Running additional validations..."
	@echo "[make] Checking file permissions..."
	@test -x tests/smoke-test.sh || (echo "ERROR: tests/smoke-test.sh not executable" && exit 1)
	@test -x tests/validate-ansible.sh || (echo "ERROR: tests/validate-ansible.sh not executable" && exit 1)
	@test -x tests/build-test.sh || (echo "ERROR: tests/build-test.sh not executable" && exit 1)
	@test -x build/generate-bindep.sh || (echo "ERROR: build/generate-bindep.sh not executable" && exit 1)
	@echo "[make] All validations passed"

# Cleanup target
clean:
	@echo "[make] Cleaning up build artifacts..."
	@rm -f build.log build-*.log
	@rm -rf deps/
	@rm -rf out/
	@echo "[make] Cleanup completed"

# Development targets
dev-setup:
	@echo "[make] Setting up development environment..."
	@chmod +x tests/*.sh build/*.sh
	@echo "[make] Development environment ready"

# Quick development cycle
dev: dev-setup generate-bindep build smoke-test
	@echo "[make] Development cycle completed"

# Production build
prod: generate-bindep build build-test validate-ansible
	@echo "[make] Production build completed successfully"
	@echo "[make] Image $(IMAGE_NAME) is ready for deployment"

# Image generation targets
qcow2: build
	@echo "[make] Generating QCOW2 image..."
	mkdir -p out
	podman pull quay.io/centos-bootc/bootc-image-builder:latest
	podman run \
		--rm --privileged --pull=newer \
		--security-opt label=type:unconfined_t \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		-v ./out:/output \
		quay.io/centos-bootc/bootc-image-builder:latest \
		--type qcow2 \
		--rootfs ext4 \
		localhost/$(IMAGE_NAME)
	@echo "[make] QCOW2 image created: out/hassos-bootc.qcow2"

iso: build
	@echo "[make] Generating ISO image..."
	mkdir -p out
	podman pull quay.io/centos-bootc/bootc-image-builder:latest
	podman run \
		--rm --privileged --pull=newer \
		--security-opt label=type:unconfined_t \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		-v ./out:/output \
		quay.io/centos-bootc/bootc-image-builder:latest \
		--type iso \
		--rootfs ext4 \
		localhost/$(IMAGE_NAME)
	@echo "[make] ISO image created: out/hassos-bootc.iso"

iso-arm64: build
	@echo "[make] Generating ARM64 ISO image..."
	mkdir -p out
	podman pull quay.io/centos-bootc/bootc-image-builder:latest
	podman run \
		--rm --privileged --pull=newer \
		--security-opt label=type:unconfined_t \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		-v ./out:/output \
		quay.io/centos-bootc/bootc-image-builder:latest \
		--type iso \
		--arch aarch64 \
		--rootfs ext4 \
		localhost/$(IMAGE_NAME)
	@echo "[make] ARM64 ISO image created: out/hassos-bootc-arm64.iso"

# Generate all image formats
images: qcow2 iso iso-arm64
	@echo "[make] All image formats generated successfully"
	@echo "[make] Available images:"
	@ls -la out/